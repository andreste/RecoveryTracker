import Testing
import Foundation
@testable import RecoveryTracker

@MainActor
struct TodayViewModelTests {

    // A provider whose four daily series are configurable; sleep is derived from
    // SleepBreakdown so we supply a per-day breakdown list. Everything else is
    // empty/nil. Mirrors the TrainingViewModelTests mock style.
    final class MockHealthProvider: HealthDataProviding {
        var hrv: [Double]
        var restingHR: [Double]
        var sleepNights: [SleepBreakdown]
        var loadByDay: [Int]

        init(hrv: [Double] = [], restingHR: [Double] = [],
             sleepNights: [SleepBreakdown] = [], loadByDay: [Int] = []) {
            self.hrv = hrv
            self.restingHR = restingHR
            self.sleepNights = sleepNights
            self.loadByDay = loadByDay
        }

        private let cal = Calendar.current
        private func date(offset: Int) -> Date {
            cal.date(byAdding: .day, value: offset, to: cal.startOfDay(for: Date()))!
        }

        // chronological, most-recent-LAST → map index 0 to oldest day.
        private func samples(_ values: [Double]) -> [HealthSample] {
            let count = values.count
            return values.enumerated().map { index, value in
                HealthSample(date: date(offset: index - (count - 1)), value: value)
            }
        }

        var isAuthorized: Bool { get async { false } }
        func requestAuthorization() async throws -> HealthAuthorizationStatus { .authorized }
        func latestHRV() async -> HealthSample? { samples(hrv).last }
        func hrvSeries(days: Int) async -> [HealthSample] { samples(hrv) }
        func latestRestingHeartRate() async -> HealthSample? { samples(restingHR).last }
        func restingHeartRateSeries(days: Int) async -> [HealthSample] { samples(restingHR) }
        func lastNightSleep() async -> SleepBreakdown? { sleepNights.last }
        func averageSleep(days: Int) async -> SleepBreakdown? { sleepNights.last }
        func recentWorkouts(limit: Int) async -> [Workout] { [] }

        func trainingLoad(for date: Date) async -> Int? {
            // Map the requested day back to an index in loadByDay (most-recent LAST).
            let today = cal.startOfDay(for: Date())
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: today).day ?? 0
            let index = (loadByDay.count - 1) - days
            guard index >= 0, index < loadByDay.count else { return nil }
            return loadByDay[index]
        }
    }

    // 31 flat baseline days with an overriding "today", matching the engine tests.
    private func series(baseline: Double, today: Double, count: Int = 31) -> [Double] {
        var values = Array(repeating: baseline, count: count - 1)
        values.append(today)
        return values
    }

    private func sleepNights(baselinePercent: Int, todayPercent: Int, count: Int = 31) -> [SleepBreakdown] {
        func breakdown(percent: Int) -> SleepBreakdown {
            // asleep == percent of a fixed 500-minute window; awake the remainder.
            let asleep = percent * 5
            return SleepBreakdown(deepMinutes: asleep / 3,
                                  remMinutes: asleep / 3,
                                  coreMinutes: asleep - 2 * (asleep / 3),
                                  awakeMinutes: 500 - asleep)
        }
        var nights = Array(repeating: breakdown(percent: baselinePercent), count: count - 1)
        nights.append(breakdown(percent: todayPercent))
        return nights
    }

    private func mockWithKnownSeries() -> MockHealthProvider {
        MockHealthProvider(
            hrv: series(baseline: 60, today: 80),
            restingHR: series(baseline: 55, today: 48),
            sleepNights: sleepNights(baselinePercent: 80, todayPercent: 92),
            loadByDay: series(baseline: 320, today: 200).map { Int($0) }
        )
    }

    // MARK: - Consistency with the engines

    @Test func scoreMetricsAndInsightMatchEnginesForKnownSeries() async {
        let mock = mockWithKnownSeries()
        let vm = TodayViewModel(health: mock)
        await vm.load()

        // Rebuild the same engine Inputs the VM should have produced.
        let inputs = await TodayViewModel.inputs(from: mock)
        let expected = ReadinessEngine.evaluate(inputs)
        let expectedInsight = InsightEngine.dailyInsight(
            from: InsightEngine.Inputs(hrv: inputs.hrv, restingHR: inputs.restingHR,
                                       sleepQuality: inputs.sleepQuality,
                                       trainingLoad: inputs.trainingLoad)
        )

        #expect(vm.score == expected.score)
        #expect(vm.metrics == expected.metrics)
        #expect(vm.insight == expectedInsight)
        #expect(vm.history.count == 7)
    }

    @Test func providerSeriesDriveTheMetricValues() async {
        let vm = TodayViewModel(health: mockWithKnownSeries())
        await vm.load()
        #expect(vm.metrics.hrv.value == 80)
        #expect(vm.metrics.restingHR.value == 48)
        #expect(vm.metrics.trainingLoad.value == 200)
        #expect(vm.metrics.sleepQuality.value == 92)
    }

    // MARK: - Sample fallback

    @Test func emptyProviderFallsBackToSampleData() async {
        let vm = TodayViewModel(health: MockHealthProvider())
        await vm.load()
        #expect(vm.score == ReadinessScore.sample)
        #expect(vm.metrics == DailyMetrics.sample)
        #expect(vm.insight == Insight.sample)
        #expect(vm.history.count == 7)
    }

    @Test func baselineDeltaAndBandSurfacedFromScore() async {
        let vm = TodayViewModel(health: mockWithKnownSeries())
        await vm.load()
        // A recovered today beats the flat baseline, so delta is positive.
        #expect(vm.score.baselineDeltaIsPositive)
        #expect(vm.score.baselineDeltaString.hasPrefix("+"))
        #expect(vm.score.band == ScoreHelpers.band(for: vm.score.value))
    }
}
