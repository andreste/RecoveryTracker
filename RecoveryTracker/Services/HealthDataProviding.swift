import Foundation

// A time-stamped scalar reading (HRV ms, resting HR bpm, …) used for series.
struct HealthSample: Equatable {
    let date: Date
    let value: Double
}

// Authorization state for the HealthKit connection, surfaced to the UI so it
// can show a "not connected" path without inspecting HealthKit directly.
enum HealthAuthorizationStatus: Equatable {
    case authorized
    case notDetermined
    case denied
    case unavailable   // device has no HealthKit (e.g. iPad without Health)
}

// The seam the app and previews depend on. `HealthKitService` is the concrete
// implementation; screen tickets inject a mock conforming to this protocol.
// All reads are async and return nil/empty rather than throwing when data is
// simply missing.
protocol HealthDataProviding {
    var isAuthorized: Bool { get async }

    // Asks the user for READ access to the four data domains. Idempotent.
    func requestAuthorization() async throws -> HealthAuthorizationStatus

    // HRV (ms).
    func latestHRV() async -> HealthSample?
    func hrvSeries(days: Int) async -> [HealthSample]

    // Resting heart rate (bpm).
    func latestRestingHeartRate() async -> HealthSample?
    func restingHeartRateSeries(days: Int) async -> [HealthSample]

    // Sleep stage breakdown.
    func lastNightSleep() async -> SleepBreakdown?
    func averageSleep(days: Int) async -> SleepBreakdown?

    // Recent completed workouts, most recent first.
    func recentWorkouts(limit: Int) async -> [Workout]

    // Active-energy-derived training load ("au") for the given day.
    func trainingLoad(for date: Date) async -> Int?
}
