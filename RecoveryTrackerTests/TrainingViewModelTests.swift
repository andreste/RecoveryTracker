import Testing
import Foundation
@testable import RecoveryTracker

@MainActor
struct TrainingViewModelTests {

    // A provider whose recentWorkouts result is configurable; everything else
    // returns empty/nil. Mirrors the OnboardingViewModelTests mock style.
    final class MockHealthProvider: HealthDataProviding {
        var workouts: [Workout]
        init(workouts: [Workout] = []) { self.workouts = workouts }

        var isAuthorized: Bool { get async { false } }
        func requestAuthorization() async throws -> HealthAuthorizationStatus { .authorized }
        func latestHRV() async -> HealthSample? { nil }
        func hrvSeries(days: Int) async -> [HealthSample] { [] }
        func latestRestingHeartRate() async -> HealthSample? { nil }
        func restingHeartRateSeries(days: Int) async -> [HealthSample] { [] }
        func lastNightSleep() async -> SleepBreakdown? { nil }
        func averageSleep(days: Int) async -> SleepBreakdown? { nil }
        func recentWorkouts(limit: Int) async -> [Workout] { workouts }
        func trainingLoad(for date: Date) async -> Int? { nil }
    }

    private let cal = Calendar.current

    private func date(daysAgo days: Int) -> Date {
        cal.date(byAdding: .day, value: -days, to: Date())!
    }

    // MARK: - Day label mapping

    @Test func dayLabelIsTodayForSameDay() {
        let now = Date()
        #expect(TrainingViewModel.dayLabel(for: now, relativeTo: now) == "Today")
    }

    @Test func dayLabelIsYesterdayForPriorDay() {
        let now = Date()
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!
        #expect(TrainingViewModel.dayLabel(for: yesterday, relativeTo: now) == "Yesterday")
    }

    @Test func dayLabelIsWeekdayForOlderDays() {
        // Anchor on a fixed weekday so the abbreviation is deterministic.
        // 2026-05-20 is a Wednesday.
        var comps = DateComponents()
        comps.year = 2026; comps.month = 5; comps.day = 20
        let wednesday = cal.date(from: comps)!
        let threeDaysLater = cal.date(byAdding: .day, value: 3, to: wednesday)! // Sat
        #expect(TrainingViewModel.dayLabel(for: wednesday, relativeTo: threeDaysLater) == "Wed")
    }

    // MARK: - Workout -> WorkoutRowData mapping

    @Test func mapsWorkoutToRowData() {
        let workout = Workout(
            sport: .run, title: "Easy aerobic run", date: date(daysAgo: 0),
            durationSeconds: 3252, primaryStat: "8.2 km · 6:36/km", recoveryCost: .low
        )
        let row = TrainingViewModel.rowData(for: workout)
        #expect(row.sport == .run)
        #expect(row.title == "Easy aerobic run")
        #expect(row.day == "Today")
        #expect(row.duration == "54:12")
        #expect(row.detail == "8.2 km · 6:36/km")
        #expect(row.cost == .low)
    }

    // MARK: - Per-workout load + thresholds

    @Test func loadBucketRespectsBoundaries() {
        #expect(TrainingViewModel.loadLevel(for: 401) == .high)
        #expect(TrainingViewModel.loadLevel(for: 400) == .medium)
        #expect(TrainingViewModel.loadLevel(for: 251) == .medium)
        #expect(TrainingViewModel.loadLevel(for: 250) == .low)
        #expect(TrainingViewModel.loadLevel(for: 0) == .low)
    }

    // MARK: - Weekly aggregation

    @Test func weeklyLoadSumsPerWeekdayAndTotal() {
        // Two workouts on a Monday, one on a Tuesday.
        var comps = DateComponents()
        comps.year = 2026; comps.month = 5; comps.day = 18 // 2026-05-18 is a Monday
        let monday = cal.date(from: comps)!
        let tuesday = cal.date(byAdding: .day, value: 1, to: monday)!

        let workouts = [
            Workout(sport: .run,  title: "A", date: monday,  durationSeconds: 60 * 60, primaryStat: "", recoveryCost: .low),    // 60 * 4 = 240
            Workout(sport: .lift, title: "B", date: monday,  durationSeconds: 30 * 60, primaryStat: "", recoveryCost: .medium), // 30 * 6 = 180
            Workout(sport: .run,  title: "C", date: tuesday, durationSeconds: 60 * 60, primaryStat: "", recoveryCost: .high)    // 60 * 9 = 540
        ]

        let week = TrainingViewModel.weeklyLoad(from: workouts, weekStart: monday)
        #expect(week.count == 7)
        #expect(week[0].load == 420)   // Monday: 240 + 180
        #expect(week[1].load == 540)   // Tuesday
        #expect(week[2].load == 0)     // Wednesday rest
        #expect(week[2].isRest == true)
        #expect(week[0].isRest == false)
        #expect(week.map(\.load).reduce(0, +) == 960)
    }

    @Test func restDaysAreZeroAndFlagged() {
        var comps = DateComponents()
        comps.year = 2026; comps.month = 5; comps.day = 18
        let monday = cal.date(from: comps)!
        let week = TrainingViewModel.weeklyLoad(from: [], weekStart: monday)
        #expect(week.allSatisfy { $0.load == 0 && $0.isRest })
        #expect(week.count == 7)
    }

    // MARK: - Sample fallback

    @Test func emptyProviderFallsBackToSampleData() async {
        let vm = TrainingViewModel(health: MockHealthProvider(workouts: []))
        await vm.load()
        #expect(!vm.workouts.isEmpty)
    }

    @Test func providerWorkoutsAreUsedWhenPresent() async {
        let workouts = [
            Workout(sport: .swim, title: "Pool session", date: date(daysAgo: 0),
                    durationSeconds: 1800, primaryStat: "1.5 km", recoveryCost: .medium)
        ]
        let vm = TrainingViewModel(health: MockHealthProvider(workouts: workouts))
        await vm.load()
        #expect(vm.workouts.count == 1)
        #expect(vm.workouts.first?.title == "Pool session")
    }
}
