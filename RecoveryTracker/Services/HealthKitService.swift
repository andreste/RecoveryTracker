import Foundation
import HealthKit

// Concrete `HealthDataProviding` backed by `HKHealthStore`.
//
// This type owns the HealthKit-specific work: declaring the read types,
// requesting authorization, running queries, and converting `HKSample`s into
// the plain raw value types that `HealthKitMapping` knows how to map. The
// pure mapping logic is unit-tested separately; the queries here only run on
// a real device with Health data, so they aren't unit-testable.
final class HealthKitService: HealthDataProviding {

    private let store = HKHealthStore()

    // MARK: Read types

    private static let hrvType = HKQuantityType(.heartRateVariabilitySDNN)
    private static let restingHRType = HKQuantityType(.restingHeartRate)
    private static let activeEnergyType = HKQuantityType(.activeEnergyBurned)
    private static let sleepType = HKCategoryType(.sleepAnalysis)
    private static let workoutType = HKObjectType.workoutType()

    private var readTypes: Set<HKObjectType> {
        [Self.hrvType, Self.restingHRType, Self.activeEnergyType,
         Self.sleepType, Self.workoutType]
    }

    // MARK: Authorization

    var isAuthorized: Bool {
        get async {
            guard HKHealthStore.isHealthDataAvailable() else { return false }
            // Read authorization can't be read back directly for privacy
            // reasons; if a recent HRV sample comes back we're effectively
            // authorized. Falls back to false on no data.
            return await latestHRV() != nil
        }
    }

    func requestAuthorization() async throws -> HealthAuthorizationStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .unavailable }
        try await store.requestAuthorization(toShare: [], read: readTypes)
        // Apple intentionally hides read-permission status; report
        // notDetermined and let callers probe via data reads.
        return .notDetermined
    }

    // MARK: Quantity series (HRV / resting HR)

    func latestHRV() async -> HealthSample? {
        await latestSample(of: Self.hrvType, unit: .secondUnit(with: .milli))
    }

    func hrvSeries(days: Int) async -> [HealthSample] {
        await series(of: Self.hrvType, unit: .secondUnit(with: .milli), days: days)
    }

    func latestRestingHeartRate() async -> HealthSample? {
        await latestSample(of: Self.restingHRType,
                           unit: HKUnit.count().unitDivided(by: .minute()))
    }

    func restingHeartRateSeries(days: Int) async -> [HealthSample] {
        await series(of: Self.restingHRType,
                     unit: HKUnit.count().unitDivided(by: .minute()), days: days)
    }

    // MARK: Sleep

    func lastNightSleep() async -> SleepBreakdown? {
        let segments = await sleepSegments(days: 1)
        return HealthKitMapping.sleepBreakdown(from: segments)
    }

    func averageSleep(days: Int) async -> SleepBreakdown? {
        let calendar = Calendar.current
        var nights: [SleepBreakdown] = []
        for offset in 0..<max(days, 1) {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: Date())
            else { continue }
            let segments = await sleepSegments(forDayEnding: day)
            if let breakdown = HealthKitMapping.sleepBreakdown(from: segments) {
                nights.append(breakdown)
            }
        }
        return HealthKitMapping.averageSleep(nights)
    }

    // MARK: Workouts

    func recentWorkouts(limit: Int) async -> [Workout] {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.workout()],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: limit
        )
        guard let workouts = try? await descriptor.result(for: store) else { return [] }
        return workouts.map { workout in
            let energy = workout.statistics(for: Self.activeEnergyType)?
                .sumQuantity()?.doubleValue(for: .kilocalorie())
            let distance = Self.distanceType(for: workout.workoutActivityType).flatMap {
                workout.statistics(for: $0)?.sumQuantity()?.doubleValue(for: .meter())
            }
            let raw = RawWorkoutSample(
                activityType: UInt(workout.workoutActivityType.rawValue),
                start: workout.startDate,
                duration: workout.duration,
                energyKilocalories: energy,
                distanceMeters: distance
            )
            return HealthKitMapping.workout(from: raw)
        }
    }

    // MARK: Training load

    func trainingLoad(for date: Date) async -> Int? {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return nil }
        let predicate = HKSamplePredicate.quantitySample(
            type: Self.activeEnergyType,
            predicate: HKQuery.predicateForSamples(withStart: start, end: end)
        )
        let descriptor = HKStatisticsQueryDescriptor(predicate: predicate, options: .cumulativeSum)
        guard let stats = try? await descriptor.result(for: store),
              let kcal = stats.sumQuantity()?.doubleValue(for: .kilocalorie())
        else { return nil }
        return HealthKitMapping.trainingLoad(activeEnergyKilocalories: kcal)
    }

    // The distance quantity type that matches a workout's activity, or nil for
    // activities without a meaningful distance (strength, yoga, etc.).
    private static func distanceType(for activity: HKWorkoutActivityType) -> HKQuantityType? {
        switch activity {
        case .running, .walking, .hiking:
            return HKQuantityType(.distanceWalkingRunning)
        case .cycling:
            return HKQuantityType(.distanceCycling)
        case .swimming:
            return HKQuantityType(.distanceSwimming)
        default:
            return nil
        }
    }

    // MARK: - Private query helpers

    private func latestSample(of type: HKQuantityType, unit: HKUnit) async -> HealthSample? {
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )
        guard let sample = try? await descriptor.result(for: store).first else { return nil }
        return HealthSample(date: sample.startDate,
                            value: sample.quantity.doubleValue(for: unit))
    }

    private func series(of type: HKQuantityType, unit: HKUnit, days: Int) async -> [HealthSample] {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -max(days, 1), to: Date())
        else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: type, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        guard let samples = try? await descriptor.result(for: store) else { return [] }
        return samples.map {
            HealthSample(date: $0.startDate, value: $0.quantity.doubleValue(for: unit))
        }
    }

    // Sleep samples whose "night" ends on (or just before) `day`. We treat a
    // night as the 18-hour window ending at noon, which captures an evening
    // bedtime through a late morning wake-up.
    private func sleepSegments(forDayEnding day: Date) async -> [RawSleepSegment] {
        guard let window = Self.sleepWindow(forDayEnding: day) else { return [] }
        return await sleepSegments(start: window.start, end: window.end)
    }

    // Pure date-window math for `sleepSegments(forDayEnding:)`, factored out so
    // it can be unit-tested without HealthKit. The night is the 18-hour window
    // ending at noon of `day`, but the end is clamped to `now` so a morning
    // open (before noon) doesn't push the end into the future and invert/empty
    // the window — which would silently drop last night's sleep.
    static func sleepWindow(forDayEnding day: Date, now: Date = Date(),
                            calendar: Calendar = .current) -> (start: Date, end: Date)? {
        let noon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
        let end = min(noon, now)
        guard let start = calendar.date(byAdding: .hour, value: -18, to: end) else { return nil }
        return (start, end)
    }

    private func sleepSegments(days: Int) async -> [RawSleepSegment] {
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -max(days, 1), to: Date())
        else { return [] }
        return await sleepSegments(start: start, end: Date())
    }

    private func sleepSegments(start: Date, end: Date) async -> [RawSleepSegment] {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [.categorySample(type: Self.sleepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )
        guard let samples = try? await descriptor.result(for: store) else { return [] }
        return samples.compactMap { sample -> RawSleepSegment? in
            guard let stage = HealthKitMapping.sleepStage(forHKValue: sample.value) else { return nil }
            let minutes = Int((sample.endDate.timeIntervalSince(sample.startDate) / 60).rounded())
            return RawSleepSegment(stage: stage, minutes: minutes)
        }
    }
}
