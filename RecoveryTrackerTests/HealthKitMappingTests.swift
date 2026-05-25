import Testing
import Foundation
@testable import RecoveryTracker

// Unit tests for the PURE mapping/aggregation logic that converts plain
// value types (RawSleepSegment / RawWorkoutSample / raw energy) into the
// app's domain models. No HealthKit types are touched here — HKSample →
// raw value conversion lives in HealthKitService and is not unit-testable.

struct SleepMappingTests {
    @Test func sumsMinutesPerStage() {
        let segments = [
            RawSleepSegment(stage: .deep,  minutes: 40),
            RawSleepSegment(stage: .deep,  minutes: 48),
            RawSleepSegment(stage: .rem,   minutes: 64),
            RawSleepSegment(stage: .core,  minutes: 120),
            RawSleepSegment(stage: .core,  minutes: 82),
            RawSleepSegment(stage: .awake, minutes: 24)
        ]
        let breakdown = HealthKitMapping.sleepBreakdown(from: segments)
        #expect(breakdown?.deepMinutes == 88)
        #expect(breakdown?.remMinutes == 64)
        #expect(breakdown?.coreMinutes == 202)
        #expect(breakdown?.awakeMinutes == 24)
    }

    @Test func emptySegmentsProduceNil() {
        #expect(HealthKitMapping.sleepBreakdown(from: []) == nil)
    }

    @Test func mapsHKSleepStageValuesToRawStages() {
        // deep → deep, rem → rem, core & asleepUnspecified → core, awake → awake.
        #expect(HealthKitMapping.sleepStage(forHKValue: 4) == .deep)   // asleepDeep
        #expect(HealthKitMapping.sleepStage(forHKValue: 5) == .rem)    // asleepREM
        #expect(HealthKitMapping.sleepStage(forHKValue: 3) == .core)   // asleepCore
        #expect(HealthKitMapping.sleepStage(forHKValue: 1) == .core)   // asleepUnspecified
        #expect(HealthKitMapping.sleepStage(forHKValue: 2) == .awake)  // awake
        #expect(HealthKitMapping.sleepStage(forHKValue: 0) == nil)     // inBed (ignored)
    }

    @Test func averagesBreakdownsAcrossNights() {
        let nights = [
            SleepBreakdown(deepMinutes: 80, remMinutes: 60, coreMinutes: 200, awakeMinutes: 20),
            SleepBreakdown(deepMinutes: 100, remMinutes: 80, coreMinutes: 220, awakeMinutes: 40)
        ]
        let avg = HealthKitMapping.averageSleep(nights)
        #expect(avg?.deepMinutes == 90)
        #expect(avg?.remMinutes == 70)
        #expect(avg?.coreMinutes == 210)
        #expect(avg?.awakeMinutes == 30)
    }

    @Test func averageOfEmptyIsNil() {
        #expect(HealthKitMapping.averageSleep([]) == nil)
    }
}

struct SleepWindowTests {
    // Pure date-window math for sleepSegments(forDayEnding:). Uses a fixed
    // calendar and `now` so results are deterministic. The night is the 18h
    // window ending at noon, but the end is clamped to `now`.
    private let cal = Calendar(identifier: .gregorian)

    private func date(_ year: Int, _ month: Int, _ day: Int,
                      _ hour: Int, _ minute: Int) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour; c.minute = minute
        return cal.date(from: c)!
    }

    @Test func pastDayWindowIsNoonMinus18hToNoon() {
        // now is well after the requested day, so no clamping occurs.
        let day = date(2026, 5, 20, 8, 0)       // requested day (any hour)
        let now = date(2026, 5, 25, 9, 0)       // five days later
        let window = HealthKitService.sleepWindow(forDayEnding: day, now: now, calendar: cal)!
        let expectedEnd = date(2026, 5, 20, 12, 0)
        let expectedStart = cal.date(byAdding: .hour, value: -18, to: expectedEnd)!
        #expect(window.end == expectedEnd)        // noon of the requested day
        #expect(window.start == expectedStart)    // 18h before noon
        #expect(window.start < window.end)
    }

    @Test func todayBeforeNoonClampsEndToNowAndStaysOrdered() {
        // Regression: opening the app before noon must not push the window end
        // into the future (which inverted/emptied the window and dropped last
        // night's sleep). End is clamped to now; window stays start < end.
        let today = date(2026, 5, 25, 9, 0)       // forDayEnding == today
        let now = date(2026, 5, 25, 9, 0)         // 9am, before noon
        let window = HealthKitService.sleepWindow(forDayEnding: today, now: now, calendar: cal)!
        #expect(window.end == now)                // clamped to now, not noon
        #expect(window.start < window.end)        // not inverted/empty
        #expect(window.start == cal.date(byAdding: .hour, value: -18, to: now)!)
    }

    @Test func todayAfterNoonEndsAtNoon() {
        let today = date(2026, 5, 25, 15, 0)
        let now = date(2026, 5, 25, 15, 0)        // 3pm, after noon
        let window = HealthKitService.sleepWindow(forDayEnding: today, now: now, calendar: cal)!
        let expectedEnd = date(2026, 5, 25, 12, 0)
        #expect(window.end == expectedEnd)        // noon, since now > noon
        #expect(window.start == cal.date(byAdding: .hour, value: -18, to: expectedEnd)!)
        #expect(window.start < window.end)
    }
}

struct WorkoutMappingTests {
    // HKWorkoutActivityType raw values: running=37, cycling=13, swimming=46,
    // traditionalStrengthTraining=50, functionalStrengthTraining=20, yoga=57.
    @Test func mapsActivityTypesToSport() {
        #expect(HealthKitMapping.sport(forActivityType: 37) == .run)
        #expect(HealthKitMapping.sport(forActivityType: 13) == .ride)
        #expect(HealthKitMapping.sport(forActivityType: 46) == .swim)
        #expect(HealthKitMapping.sport(forActivityType: 50) == .lift)
        #expect(HealthKitMapping.sport(forActivityType: 20) == .lift)
        #expect(HealthKitMapping.sport(forActivityType: 57) == .yoga)
    }

    @Test func unknownActivityDefaultsToRun() {
        #expect(HealthKitMapping.sport(forActivityType: 9999) == .run)
    }

    // Recovery cost heuristic — a "load" score = minutes + (kcal / 5).
    // low < 60, medium 60..<140, high >= 140.
    @Test func recoveryCostLowForShortEasyEffort() {
        // 30 min, 150 kcal → 30 + 30 = 60? -> ensure below: 25 min, 100 kcal = 25+20 = 45
        let cost = HealthKitMapping.recoveryCost(durationSeconds: 25 * 60, energyKilocalories: 100)
        #expect(cost == .low)
    }

    @Test func recoveryCostMediumForModerateEffort() {
        // 50 min, 250 kcal → 50 + 50 = 100 → medium
        let cost = HealthKitMapping.recoveryCost(durationSeconds: 50 * 60, energyKilocalories: 250)
        #expect(cost == .medium)
    }

    @Test func recoveryCostHighForLongHardEffort() {
        // 100 min, 800 kcal → 100 + 160 = 260 → high
        let cost = HealthKitMapping.recoveryCost(durationSeconds: 100 * 60, energyKilocalories: 800)
        #expect(cost == .high)
    }

    @Test func recoveryCostHandlesMissingEnergy() {
        // 70 min, no energy → 70 → medium
        let cost = HealthKitMapping.recoveryCost(durationSeconds: 70 * 60, energyKilocalories: nil)
        #expect(cost == .medium)
    }

    @Test func buildsWorkoutWithDurationAndPrimaryStat() {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let raw = RawWorkoutSample(activityType: 37, start: date, duration: 3252,
                                   energyKilocalories: 420, distanceMeters: 8200)
        let workout = HealthKitMapping.workout(from: raw)
        #expect(workout.sport == .run)
        #expect(workout.date == date)
        #expect(workout.durationSeconds == 3252)
        // 3252s → "54:12" via TimeFormatting.clockDuration
        #expect(workout.durationFormatted == "54:12")
        // primaryStat shows distance for distance-based sports.
        #expect(workout.primaryStat == "8.2 km · 420 kcal")
        #expect(workout.title == "Running")
    }

    @Test func primaryStatOmitsDistanceWhenAbsent() {
        let raw = RawWorkoutSample(activityType: 50, start: Date(), duration: 2910,
                                   energyKilocalories: 180, distanceMeters: nil)
        let workout = HealthKitMapping.workout(from: raw)
        #expect(workout.sport == .lift)
        #expect(workout.primaryStat == "180 kcal")
    }
}

struct TrainingLoadMappingTests {
    // Training load = active energy in kcal, divided by 10 and rounded → "au".
    @Test func derivesTrainingLoadFromActiveEnergy() {
        #expect(HealthKitMapping.trainingLoad(activeEnergyKilocalories: 3120) == 312)
        #expect(HealthKitMapping.trainingLoad(activeEnergyKilocalories: 0) == 0)
        #expect(HealthKitMapping.trainingLoad(activeEnergyKilocalories: 3125) == 313)
    }
}
