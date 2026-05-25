import Testing
@testable import RecoveryTracker

struct ScoreBandTests {
    @Test func goodBandAtAndAboveSeventyFive() {
        #expect(ScoreHelpers.band(for: 100) == .good)
        #expect(ScoreHelpers.band(for: 75) == .good)
    }

    @Test func moderateBandBetweenFiftyFiveAndSeventyFour() {
        #expect(ScoreHelpers.band(for: 74) == .moderate)
        #expect(ScoreHelpers.band(for: 55) == .moderate)
    }

    @Test func poorBandBelowFiftyFive() {
        #expect(ScoreHelpers.band(for: 54) == .poor)
        #expect(ScoreHelpers.band(for: 0) == .poor)
    }
}

struct ReadinessScoreTests {
    @Test func derivesBandFromValue() {
        #expect(ReadinessScore(value: 91, baselineDelta: 0).band == .good)
        #expect(ReadinessScore(value: 62, baselineDelta: 0).band == .moderate)
        #expect(ReadinessScore(value: 42, baselineDelta: 0).band == .poor)
    }

    @Test func exposesStatusAndAdviceLabels() {
        let score = ReadinessScore(value: 78, baselineDelta: 8)
        #expect(score.status == "Good")
        #expect(score.advice == "Train normally")
    }

    @Test func positiveBaselineDeltaFormatsWithSign() {
        let score = ReadinessScore(value: 78, baselineDelta: 8)
        #expect(score.baselineDeltaIsPositive == true)
        #expect(score.baselineDeltaString == "+8")
    }

    @Test func negativeBaselineDeltaFormatsWithSign() {
        let score = ReadinessScore(value: 42, baselineDelta: -28)
        #expect(score.baselineDeltaIsPositive == false)
        #expect(score.baselineDeltaString == "-28")
    }

    @Test func zeroBaselineDeltaHasNoSign() {
        let score = ReadinessScore(value: 70, baselineDelta: 0)
        #expect(score.baselineDeltaString == "0")
    }
}
