import Testing
@testable import RecoveryTracker

struct DualLineChartTests {
    // Regression: HRV (one sample per measurement) and load (one value per
    // workout day) come from independent HealthKit queries and routinely differ
    // in length. The chart indexes both series in lockstep, so the point count
    // must clamp to the shorter array or it reads out of bounds and crashes.
    @Test func pointCountClampsToShorterSeriesWhenHRVIsLonger() {
        let hrv = Array(repeating: 60.0, count: 14)
        let load = Array(repeating: 200.0, count: 6)
        #expect(DualLineChart.renderablePointCount(hrv: hrv, load: load) == 6)
    }

    @Test func pointCountClampsToShorterSeriesWhenLoadIsLonger() {
        let hrv = Array(repeating: 60.0, count: 3)
        let load = Array(repeating: 200.0, count: 9)
        #expect(DualLineChart.renderablePointCount(hrv: hrv, load: load) == 3)
    }

    @Test func pointCountMatchesEqualLengthSeries() {
        let hrv = Array(repeating: 60.0, count: 8)
        let load = Array(repeating: 200.0, count: 8)
        #expect(DualLineChart.renderablePointCount(hrv: hrv, load: load) == 8)
    }

    @Test func pointCountIsZeroWhenEitherSeriesIsEmpty() {
        #expect(DualLineChart.renderablePointCount(hrv: [], load: [200]) == 0)
        #expect(DualLineChart.renderablePointCount(hrv: [60], load: []) == 0)
    }
}
