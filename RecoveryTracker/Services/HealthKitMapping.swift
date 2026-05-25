import Foundation

// MARK: - Raw value types
//
// HealthKit sample types (HKWorkout, HKCategorySample, …) cannot be
// constructed in unit tests and don't return data in the simulator. So the
// service first converts HKSamples into these plain value types, and all the
// pure mapping/aggregation logic below operates on them. Only this layer is
// unit-tested; the live HKHealthStore queries are not.

// A single sleep stage segment, already classified and measured in minutes.
struct RawSleepSegment: Equatable {
    enum Stage: Equatable {
        case deep, rem, core, awake
    }
    let stage: Stage
    let minutes: Int
}

// A completed workout reduced to the fields we map into a `Workout`.
// `activityType` is the raw value of `HKWorkoutActivityType`, keeping this
// type free of any HealthKit import.
struct RawWorkoutSample: Equatable {
    let activityType: UInt
    let start: Date
    let duration: TimeInterval
    let energyKilocalories: Double?
    let distanceMeters: Double?
}

// MARK: - Pure mappers

enum HealthKitMapping {

    // MARK: Sleep

    // Maps an `HKCategoryValueSleepAnalysis` raw value to a raw sleep stage.
    // Returns nil for values we don't track (e.g. `inBed`), so callers can
    // skip them. HK raw values: inBed=0, asleepUnspecified=1, awake=2,
    // asleepCore=3, asleepDeep=4, asleepREM=5.
    static func sleepStage(forHKValue value: Int) -> RawSleepSegment.Stage? {
        switch value {
        case 4:        return .deep              // asleepDeep
        case 5:        return .rem               // asleepREM
        case 3, 1:     return .core              // asleepCore, asleepUnspecified
        case 2:        return .awake             // awake
        default:       return nil                // inBed and anything unknown
        }
    }

    // Sums segment minutes per stage into a `SleepBreakdown`.
    // Returns nil when there are no segments (no data for the night).
    static func sleepBreakdown(from segments: [RawSleepSegment]) -> SleepBreakdown? {
        guard !segments.isEmpty else { return nil }
        var deep = 0, rem = 0, core = 0, awake = 0
        for segment in segments {
            switch segment.stage {
            case .deep:  deep  += segment.minutes
            case .rem:   rem   += segment.minutes
            case .core:  core  += segment.minutes
            case .awake: awake += segment.minutes
            }
        }
        return SleepBreakdown(deepMinutes: deep, remMinutes: rem,
                              coreMinutes: core, awakeMinutes: awake)
    }

    // Averages a set of nightly breakdowns (per-stage mean, rounded).
    static func averageSleep(_ nights: [SleepBreakdown]) -> SleepBreakdown? {
        guard !nights.isEmpty else { return nil }
        let count = Double(nights.count)
        func mean(_ keyPath: (SleepBreakdown) -> Int) -> Int {
            Int((Double(nights.reduce(0) { $0 + keyPath($1) }) / count).rounded())
        }
        return SleepBreakdown(
            deepMinutes:  mean(\.deepMinutes),
            remMinutes:   mean(\.remMinutes),
            coreMinutes:  mean(\.coreMinutes),
            awakeMinutes: mean(\.awakeMinutes)
        )
    }

    // MARK: Workouts

    // Maps an `HKWorkoutActivityType` raw value to the app's `Sport`.
    // Unknown activities default to `.run` so the UI always has an icon.
    static func sport(forActivityType activityType: UInt) -> Sport {
        switch activityType {
        case 13:       return .ride   // cycling
        case 46:       return .swim   // swimming
        case 50, 20:   return .lift   // traditional / functional strength training
        case 57:       return .yoga   // yoga
        case 37:       return .run    // running
        default:       return .run    // sensible default
        }
    }

    // Recovery-cost heuristic.
    //
    // We combine duration and energy into a single "load" score:
    //     load = minutes + (kcal / 5)
    // then bucket it:
    //     low    : load < 60
    //     medium : 60 <= load < 140
    //     high   : load >= 140
    //
    // Rationale: ~5 kcal/min is a light effort, so the energy term roughly
    // doubles the weight of an intense minute vs. an easy one. A 30-min easy
    // session lands "low", an hour at moderate intensity lands "medium", and
    // a long or very hard session lands "high". Energy is optional — when
    // absent we fall back to duration alone.
    static func recoveryCost(durationSeconds: Int, energyKilocalories: Double?) -> RecoveryCost {
        let minutes = Double(durationSeconds) / 60.0
        let energyTerm = (energyKilocalories ?? 0) / 5.0
        let load = minutes + energyTerm
        switch load {
        case ..<60:   return .low
        case ..<140:  return .medium
        default:      return .high
        }
    }

    // Builds a domain `Workout` from a raw sample.
    static func workout(from raw: RawWorkoutSample) -> Workout {
        let sport = sport(forActivityType: raw.activityType)
        let durationSeconds = Int(raw.duration)
        return Workout(
            sport: sport,
            title: sport.displayName,
            date: raw.start,
            durationSeconds: durationSeconds,
            primaryStat: primaryStat(from: raw),
            recoveryCost: recoveryCost(durationSeconds: durationSeconds,
                                       energyKilocalories: raw.energyKilocalories)
        )
    }

    // Composes the one-line summary, e.g. "8.2 km · 420 kcal".
    // Distance is shown when present; energy when present; falls back to a dash.
    private static func primaryStat(from raw: RawWorkoutSample) -> String {
        var parts: [String] = []
        if let meters = raw.distanceMeters, meters > 0 {
            let km = meters / 1000.0
            parts.append(String(format: "%.1f km", km))
        }
        if let kcal = raw.energyKilocalories, kcal > 0 {
            parts.append("\(Int(kcal.rounded())) kcal")
        }
        return parts.isEmpty ? "—" : parts.joined(separator: " · ")
    }

    // MARK: Training load

    // Active-energy-based training load (arbitrary "au" units): kcal / 10,
    // rounded. Mirrors the sample data scale (~312 au for a typical day).
    static func trainingLoad(activeEnergyKilocalories kcal: Double) -> Int {
        Int((kcal / 10.0).rounded())
    }
}
