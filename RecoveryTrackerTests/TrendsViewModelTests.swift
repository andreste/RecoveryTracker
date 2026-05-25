import Testing
import Foundation
@testable import RecoveryTracker

@MainActor
struct TrendsViewModelTests {

    // A provider whose four daily series are configurable; sleep is exposed via
    // averageSleep. Mirrors the TodayViewModelTests mock style.
    final class MockHealthProvider: HealthDataProviding {
        var hrv: [Double]
        var restingHR: [Double]
        var sleepAverage: SleepBreakdown?
        var loadByDay: [Int]

        init(hrv: [Double] = [], restingHR: [Double] = [],
             sleepAverage: SleepBreakdown? = nil, loadByDay: [Int] = []) {
            self.hrv = hrv
            self.restingHR = restingHR
            self.sleepAverage = sleepAverage
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
        func lastNightSleep() async -> SleepBreakdown? { sleepAverage }
        func averageSleep(days: Int) async -> SleepBreakdown? { sleepAverage }
        func recentWorkouts(limit: Int) async -> [Workout] { [] }

        func trainingLoad(for date: Date) async -> Int? {
            let today = cal.startOfDay(for: Date())
            let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: today).day ?? 0
            let index = (loadByDay.count - 1) - days
            guard index >= 0, index < loadByDay.count else { return nil }
            return loadByDay[index]
        }
    }

    // A 28-element ramp so the two series differ and have variance.
    private func ramp(start: Double, step: Double, count: Int = 28) -> [Double] {
        (0..<count).map { start + Double($0) * step }
    }

    private func mockWithKnownSeries() -> MockHealthProvider {
        MockHealthProvider(
            hrv: ramp(start: 55, step: 0.7),
            restingHR: ramp(start: 50, step: 0.1),
            sleepAverage: SleepBreakdown(deepMinutes: 90, remMinutes: 70,
                                         coreMinutes: 200, awakeMinutes: 20),
            loadByDay: ramp(start: 200, step: 8).map { Int($0) }
        )
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Known series surface on the VM

    @Test func exposesProviderSeriesAndAverages() async {
        let mock = mockWithKnownSeries()
        let vm = TrendsViewModel(health: mock)
        await vm.load()

        let expectedHRV = mock.hrv
        let expectedLoad = mock.loadByDay.map(Double.init)

        #expect(vm.hrvSeries == expectedHRV)
        #expect(vm.loadSeries == expectedLoad)
        #expect(abs(vm.hrvAverage - average(expectedHRV)) < 0.0001)
        #expect(abs(vm.loadAverage - average(expectedLoad)) < 0.0001)
    }

    @Test func correlationsMatchInsightEngineForKnownSeries() async {
        let mock = mockWithKnownSeries()
        let vm = TrendsViewModel(health: mock)
        await vm.load()

        let inputs = await TrendsViewModel.inputs(from: mock)
        let expected = InsightEngine.correlations(from: inputs)

        // Correlation carries a random UUID id, so compare the meaningful fields.
        #expect(!vm.correlations.isEmpty)
        #expect(vm.correlations.count == expected.count)
        for (actual, want) in zip(vm.correlations, expected) {
            #expect(actual.xLabel == want.xLabel)
            #expect(actual.yLabel == want.yLabel)
            #expect(abs(actual.r - want.r) < 0.0001)
            #expect(actual.note == want.note)
        }
    }

    @Test func sleepBreakdownSurfacesFromProvider() async {
        let mock = mockWithKnownSeries()
        let vm = TrendsViewModel(health: mock)
        await vm.load()

        #expect(vm.sleep == mock.sleepAverage)
        #expect(vm.sleep.minutes(for: .deep) == 90)
        #expect(vm.sleep.minutes(for: .rem) == 70)
        #expect(vm.sleep.totalInBedMinutes == 380)
        #expect(vm.sleep.percentage(for: .deep) == mock.sleepAverage!.percentage(for: .deep))
    }

    // MARK: - Sample fallback

    @Test func emptyProviderFallsBackToSampleData() async {
        let vm = TrendsViewModel(health: MockHealthProvider())
        await vm.load()

        #expect(!vm.hrvSeries.isEmpty)
        #expect(!vm.loadSeries.isEmpty)
        #expect(vm.hrvSeries.count == vm.loadSeries.count)
        #expect(vm.sleep == SleepBreakdown.sample)
        #expect(!vm.correlations.isEmpty)
        #expect(vm.correlations == Correlation.samples)
    }
}
