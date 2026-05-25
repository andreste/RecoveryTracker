import Foundation
import Testing
@testable import RecoveryTracker

struct DisciplineTests {
    @Test func displayNames() {
        #expect(Discipline.running.displayName == "Running")
        #expect(Discipline.triathlon.displayName == "Triathlon")
    }

    @Test func subtitles() {
        #expect(Discipline.running.subtitle == "Road · trail")
        #expect(Discipline.triathlon.subtitle == "Swim · bike · run")
    }

    @Test func hasAllFourCases() {
        #expect(Discipline.allCases.count == 4)
    }
}

struct ClockDurationTests {
    @Test func minutesAndSecondsUnderAnHour() {
        #expect(TimeFormatting.clockDuration(3252) == "54:12")
        #expect(TimeFormatting.clockDuration(1920) == "32:00")
    }

    @Test func hoursMinutesSecondsOverAnHour() {
        #expect(TimeFormatting.clockDuration(4101) == "1:08:21")
    }
}

struct WorkoutTests {
    @Test func durationFormattedUsesClockDuration() {
        let w = Workout(sport: .run, title: "Easy aerobic run", date: Date(),
                        durationSeconds: 3252, primaryStat: "8.2 km · 6:36/km", recoveryCost: .low)
        #expect(w.durationFormatted == "54:12")
    }
}

struct CorrelationTests {
    @Test func positiveCoefficient() {
        let c = Correlation(xLabel: "Sleep quality", yLabel: "Next-day HRV", r: 0.71, note: "")
        #expect(c.isPositive == true)
    }

    @Test func filledSegmentsRoundFromMagnitude() {
        #expect(Correlation(xLabel: "", yLabel: "", r: 0.71, note: "").filledSegments == 7)
        #expect(Correlation(xLabel: "", yLabel: "", r: -0.64, note: "").filledSegments == 6)
    }

    // Regression: filledSegments must clamp to 10 even when |r| exceeds 1.0,
    // matching the view layer's min(10, ...) so the meter never overflows.
    @Test func filledSegmentsClampToTen() {
        #expect(Correlation(xLabel: "", yLabel: "", r: 1.0, note: "").filledSegments == 10)
        #expect(Correlation(xLabel: "", yLabel: "", r: 1.5, note: "").filledSegments == 10)
        #expect(Correlation(xLabel: "", yLabel: "", r: -1.5, note: "").filledSegments == 10)
    }

    @Test func strengthLabelDescribesMagnitudeAndDirection() {
        #expect(Correlation(xLabel: "", yLabel: "", r: 0.71, note: "").strengthLabel == "Strong positive")
        #expect(Correlation(xLabel: "", yLabel: "", r: 0.58, note: "").strengthLabel == "Moderate positive")
        #expect(Correlation(xLabel: "", yLabel: "", r: -0.64, note: "").strengthLabel == "Strong negative")
    }
}

struct InsightTests {
    @Test func sentimentBadgeLabels() {
        #expect(Insight.Sentiment.positive.label == "POSITIVE")
        #expect(Insight.Sentiment.caution.label == "CAUTION")
    }
}

struct TrainingGoalTests {
    @Test func displayName() {
        #expect(TrainingGoal.marathon.displayName == "Marathon")
        #expect(TrainingGoal.generalFitness.displayName == "General fitness")
    }
}
