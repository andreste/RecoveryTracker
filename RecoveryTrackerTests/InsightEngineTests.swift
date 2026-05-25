import Testing
import Foundation
@testable import RecoveryTracker

// Tests for the pure InsightEngine. No HealthKit / SwiftUI involved.
//
// Input convention under test: four arrays of daily values, chronological
// (most-recent-LAST). The final element is "today". Trends compare the most
// recent values against earlier ones in the same series; correlations align
// the series element-by-element over their common trailing window.
struct InsightEngineTests {

    // MARK: - Pearson r

    @Test func pearsonPerfectlyCorrelatedIsOne() {
        let x = [1.0, 2, 3, 4, 5]
        let y = [2.0, 4, 6, 8, 10]
        let r = InsightEngine.pearson(x, y)
        #expect(abs(r - 1.0) < 0.0001)
    }

    @Test func pearsonPerfectlyInverseIsMinusOne() {
        let x = [1.0, 2, 3, 4, 5]
        let y = [10.0, 8, 6, 4, 2]
        let r = InsightEngine.pearson(x, y)
        #expect(abs(r - (-1.0)) < 0.0001)
    }

    @Test func pearsonFlatVarianceIsZeroNotCrash() {
        let x = [3.0, 3, 3, 3, 3]
        let y = [1.0, 2, 3, 4, 5]
        let r = InsightEngine.pearson(x, y)
        #expect(abs(r - 0.0) < 0.0001)
    }

    @Test func pearsonFewerThanTwoPointsIsZero() {
        #expect(InsightEngine.pearson([], []) == 0)
        #expect(InsightEngine.pearson([1.0], [2.0]) == 0)
    }

    @Test func pearsonAlignsToShorterCommonWindow() {
        // Differing lengths: align on the trailing overlap.
        let x = [99.0, 1, 2, 3, 4, 5]
        let y = [2.0, 4, 6, 8, 10]
        let r = InsightEngine.pearson(x, y)
        #expect(abs(r - 1.0) < 0.0001)
    }

    // MARK: - Daily insight

    // Builds a series rising from `start` to `end` over `count` days.
    private func ramp(start: Double, end: Double, count: Int = 14) -> [Double] {
        guard count > 1 else { return [start] }
        let step = (end - start) / Double(count - 1)
        return (0..<count).map { start + step * Double($0) }
    }

    private func flat(_ value: Double, count: Int = 14) -> [Double] {
        Array(repeating: value, count: count)
    }

    @Test func risingHRVYieldsPositiveInsightWithPercent() {
        let inputs = InsightEngine.Inputs(
            hrv: ramp(start: 50, end: 65),
            restingHR: flat(52),
            sleepQuality: flat(80),
            trainingLoad: flat(300)
        )
        let insight = InsightEngine.dailyInsight(from: inputs)
        #expect(insight.sentiment == .positive)
        // % change of HRV short window vs prior window must appear in the body.
        #expect(insight.body.contains("%"))
    }

    @Test func fallingHRVYieldsCautionInsight() {
        let inputs = InsightEngine.Inputs(
            hrv: ramp(start: 65, end: 48),
            restingHR: flat(52),
            sleepQuality: flat(80),
            trainingLoad: flat(300)
        )
        let insight = InsightEngine.dailyInsight(from: inputs)
        #expect(insight.sentiment == .caution)
    }

    @Test func risingRestingHRYieldsCautionInsight() {
        let inputs = InsightEngine.Inputs(
            hrv: flat(60),
            restingHR: ramp(start: 50, end: 60),
            sleepQuality: flat(80),
            trainingLoad: flat(300)
        )
        let insight = InsightEngine.dailyInsight(from: inputs)
        #expect(insight.sentiment == .caution)
    }

    @Test func flatSeriesYieldsNeutralInsight() {
        let inputs = InsightEngine.Inputs(
            hrv: flat(60),
            restingHR: flat(52),
            sleepQuality: flat(80),
            trainingLoad: flat(300)
        )
        let insight = InsightEngine.dailyInsight(from: inputs)
        #expect(insight.sentiment == .neutral)
    }

    @Test func emptyInputsYieldNeutralInsightWithoutCrashing() {
        let inputs = InsightEngine.Inputs(hrv: [], restingHR: [], sleepQuality: [], trainingLoad: [])
        let insight = InsightEngine.dailyInsight(from: inputs)
        #expect(insight.sentiment == .neutral)
    }

    @Test func singlePointInputsYieldNeutralInsightWithoutCrashing() {
        let inputs = InsightEngine.Inputs(hrv: [60], restingHR: [52], sleepQuality: [80], trainingLoad: [300])
        let insight = InsightEngine.dailyInsight(from: inputs)
        #expect(insight.sentiment == .neutral)
    }

    // MARK: - Correlations

    @Test func correlationsRankedByAbsoluteRStrongestFirst() {
        let inputs = InsightEngine.Inputs(
            hrv:          [50, 52, 54, 56, 58, 60, 62, 64],
            restingHR:    [60, 59, 58, 57, 56, 55, 54, 53], // strong inverse w/ load below
            sleepQuality: [70, 90, 60, 95, 65, 92, 68, 88],
            trainingLoad: [300, 320, 340, 360, 380, 400, 420, 440]
        )
        let correlations = InsightEngine.correlations(from: inputs)
        #expect(!correlations.isEmpty)
        // Ranked strongest first.
        let magnitudes = correlations.map { abs($0.r) }
        #expect(magnitudes == magnitudes.sorted(by: >))
    }

    @Test func correlationsCappedAtThree() {
        let inputs = InsightEngine.Inputs(
            hrv:          [50, 52, 54, 56, 58, 60, 62, 64],
            restingHR:    [60, 59, 58, 57, 56, 55, 54, 53],
            sleepQuality: [70, 72, 74, 76, 78, 80, 82, 84],
            trainingLoad: [300, 320, 340, 360, 380, 400, 420, 440]
        )
        let correlations = InsightEngine.correlations(from: inputs)
        #expect(correlations.count <= 3)
    }

    @Test func correlationSignMatchesRelationship() {
        // Training load up, resting HR up → positive correlation.
        let inputs = InsightEngine.Inputs(
            hrv:          flat(60, count: 8),
            restingHR:    [50, 51, 52, 53, 54, 55, 56, 57],
            sleepQuality: flat(80, count: 8),
            trainingLoad: [300, 320, 340, 360, 380, 400, 420, 440]
        )
        let correlations = InsightEngine.correlations(from: inputs)
        let loadVsRHR = correlations.first { $0.xLabel.contains("load") || $0.yLabel.contains("Resting") }
        #expect(loadVsRHR != nil)
        #expect(loadVsRHR?.isPositive == true)
    }

    @Test func emptyInputsYieldNoCorrelationsWithoutCrashing() {
        let inputs = InsightEngine.Inputs(hrv: [], restingHR: [], sleepQuality: [], trainingLoad: [])
        #expect(InsightEngine.correlations(from: inputs).isEmpty)
    }
}
