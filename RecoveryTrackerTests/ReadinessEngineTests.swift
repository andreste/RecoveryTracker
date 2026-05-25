import Testing
import Foundation
@testable import RecoveryTracker

// Tests for the pure ReadinessEngine. No HealthKit / SwiftUI involved.
//
// Input convention under test: four arrays of daily values, chronological
// (most-recent-LAST). The final element is "today"; the 30 days before it
// form the rolling baseline and the 7 days before it the short-term average.
struct ReadinessEngineTests {

    // Builds 31 days of flat baseline values then overrides "today".
    private func series(baseline: Double, today: Double, count: Int = 31) -> [Double] {
        var values = Array(repeating: baseline, count: count - 1)
        values.append(today)
        return values
    }

    // A clearly-recovered today: HRV high, RHR low, sleep high, load low.
    private func recoveredInputs() -> ReadinessEngine.Inputs {
        ReadinessEngine.Inputs(
            hrv:          series(baseline: 60, today: 80),
            restingHR:    series(baseline: 55, today: 48),
            sleepQuality: series(baseline: 80, today: 92),
            trainingLoad: series(baseline: 320, today: 200)
        )
    }

    // A clearly-fatigued today: HRV low, RHR high, sleep poor, load high.
    private func fatiguedInputs() -> ReadinessEngine.Inputs {
        ReadinessEngine.Inputs(
            hrv:          series(baseline: 60, today: 40),
            restingHR:    series(baseline: 55, today: 64),
            sleepQuality: series(baseline: 80, today: 60),
            trainingLoad: series(baseline: 320, today: 460)
        )
    }

    @Test func scoreIsWithinZeroToHundred() {
        let result = ReadinessEngine.evaluate(recoveredInputs())
        #expect(result.score.value >= 0)
        #expect(result.score.value <= 100)
    }

    @Test func extremeRecoveryClampsToHundred() {
        let inputs = ReadinessEngine.Inputs(
            hrv:          series(baseline: 60, today: 500),
            restingHR:    series(baseline: 55, today: 30),
            sleepQuality: series(baseline: 80, today: 100),
            trainingLoad: series(baseline: 320, today: 0)
        )
        #expect(ReadinessEngine.evaluate(inputs).score.value == 100)
    }

    @Test func extremeFatigueClampsToZero() {
        let inputs = ReadinessEngine.Inputs(
            hrv:          series(baseline: 60, today: 1),
            restingHR:    series(baseline: 55, today: 200),
            sleepQuality: series(baseline: 80, today: 0),
            trainingLoad: series(baseline: 320, today: 5000)
        )
        #expect(ReadinessEngine.evaluate(inputs).score.value == 0)
    }

    @Test func recoveredScoresHigherThanFatigued() {
        let recovered = ReadinessEngine.evaluate(recoveredInputs()).score.value
        let fatigued = ReadinessEngine.evaluate(fatiguedInputs()).score.value
        #expect(recovered > fatigued)
    }

    @Test func baselineDeltaPositiveWhenTodayBeatsBaseline() {
        // A flat baseline scores 50 (today == baseline on every metric);
        // a recovered today must come out above that, so delta > 0.
        let result = ReadinessEngine.evaluate(recoveredInputs())
        #expect(result.score.baselineDelta > 0)
        #expect(result.score.value - result.score.baselineDelta == 50)
    }

    @Test func baselineDeltaNegativeWhenTodayTrailsBaseline() {
        let result = ReadinessEngine.evaluate(fatiguedInputs())
        #expect(result.score.baselineDelta < 0)
    }

    @Test func sevenDayMetricsCarryValuesUnitsAndGoodUp() {
        let result = ReadinessEngine.evaluate(recoveredInputs())
        let m = result.metrics

        #expect(m.hrv.kind == .hrv)
        #expect(m.hrv.value == 80)
        #expect(m.hrv.unit == "ms")
        #expect(m.hrv.delta.goodUp == true)

        #expect(m.restingHR.value == 48)
        #expect(m.restingHR.unit == "bpm")
        #expect(m.restingHR.delta.goodUp == false)

        #expect(m.sleepQuality.value == 92)
        #expect(m.sleepQuality.unit == "%")
        #expect(m.sleepQuality.delta.goodUp == true)

        #expect(m.trainingLoad.value == 200)
        #expect(m.trainingLoad.unit == "au")
        #expect(m.trainingLoad.delta.goodUp == false)
    }

    @Test func metricDeltaIsTodayMinusSevenDayAverage() {
        // 7-day window before today is flat at the baseline, so delta = today - baseline.
        let result = ReadinessEngine.evaluate(recoveredInputs())
        #expect(result.metrics.hrv.delta.value == 20)          // 80 - 60
        #expect(result.metrics.restingHR.delta.value == -7)    // 48 - 55
        #expect(result.metrics.sleepQuality.delta.value == 12) // 92 - 80
        #expect(result.metrics.trainingLoad.delta.value == -120) // 200 - 320
    }

    @Test func historyHasSevenDaysWithInRangeScores() {
        let result = ReadinessEngine.evaluate(recoveredInputs())
        #expect(result.history.count == 7)
        for day in result.history {
            #expect(day.score >= 0)
            #expect(day.score <= 100)
        }
        // Last entry is today and matches the headline score.
        #expect(result.history.last?.score == result.score.value)
    }

    @Test func emptyInputsProduceNeutralScoreWithoutCrashing() {
        let empty = ReadinessEngine.Inputs(hrv: [], restingHR: [], sleepQuality: [], trainingLoad: [])
        let result = ReadinessEngine.evaluate(empty)
        #expect(result.score.value == 50)
        #expect(result.history.count == 7)
    }

    @Test func nonFiniteInputsDoNotCrash() {
        // HealthKit can hand us garbage; NaN/inf must not trap on the Int conversion.
        let inputs = ReadinessEngine.Inputs(
            hrv:          series(baseline: 60, today: .nan),
            restingHR:    series(baseline: 55, today: .infinity),
            sleepQuality: series(baseline: 80, today: 92),
            trainingLoad: series(baseline: 320, today: 200)
        )
        let result = ReadinessEngine.evaluate(inputs)
        #expect(result.score.value >= 0)
        #expect(result.score.value <= 100)
    }
}
