import Testing
@testable import RecoveryTracker

struct MetricDeltaTests {
    @Test func increaseIsImprovementWhenUpIsGood() {
        let delta = MetricDelta(value: 4, goodUp: true)
        #expect(delta.isImprovement == true)
        #expect(delta.isNeutral == false)
    }

    @Test func decreaseIsRegressionWhenUpIsGood() {
        #expect(MetricDelta(value: -3, goodUp: true).isImprovement == false)
    }

    @Test func decreaseIsImprovementWhenDownIsGood() {
        // Resting HR: lower is better
        #expect(MetricDelta(value: -2, goodUp: false).isImprovement == true)
    }

    @Test func increaseIsRegressionWhenDownIsGood() {
        #expect(MetricDelta(value: 18, goodUp: false).isImprovement == false)
    }

    @Test func zeroIsNeutralAndNotImprovement() {
        let delta = MetricDelta(value: 0, goodUp: true)
        #expect(delta.isNeutral == true)
        #expect(delta.isImprovement == false)
    }
}

struct MetricTests {
    @Test func idMatchesKind() {
        let m = Metric(kind: .hrv, value: 68, unit: "ms", delta: MetricDelta(value: 4, goodUp: true))
        #expect(m.id == "hrv")
    }

    @Test func kindHasDisplayName() {
        #expect(Metric.Kind.hrv.displayName == "HRV")
        #expect(Metric.Kind.restingHR.displayName == "Resting HR")
        #expect(Metric.Kind.sleepQuality.displayName == "Sleep quality")
        #expect(Metric.Kind.trainingLoad.displayName == "Training load")
    }
}

struct DailyMetricsTests {
    @Test func allReturnsMetricsInDisplayOrder() {
        let metrics = DailyMetrics(
            hrv: Metric(kind: .hrv, value: 68, unit: "ms", delta: MetricDelta(value: 4, goodUp: true)),
            restingHR: Metric(kind: .restingHR, value: 52, unit: "bpm", delta: MetricDelta(value: -2, goodUp: false)),
            sleepQuality: Metric(kind: .sleepQuality, value: 84, unit: "%", delta: MetricDelta(value: 3, goodUp: true)),
            trainingLoad: Metric(kind: .trainingLoad, value: 312, unit: "au", delta: MetricDelta(value: 18, goodUp: false))
        )
        #expect(metrics.all.map(\.kind) == [.hrv, .restingHR, .sleepQuality, .trainingLoad])
    }
}

struct SleepBreakdownTests {
    private let sample = SleepBreakdown(deepMinutes: 90, remMinutes: 60, coreMinutes: 210, awakeMinutes: 30)

    @Test func totalInBedIsSumOfStages() {
        #expect(sample.totalInBedMinutes == 390)
    }

    @Test func asleepExcludesAwake() {
        #expect(sample.asleepMinutes == 360)
    }

    @Test func percentageIsStageOverTotalRounded() {
        #expect(sample.percentage(for: .deep) == 23)   // 90/390 ≈ 23%
        #expect(sample.percentage(for: .core) == 54)   // 210/390 ≈ 54%
    }

    @Test func minutesForStage() {
        #expect(sample.minutes(for: .rem) == 60)
        #expect(sample.minutes(for: .awake) == 30)
    }
}

struct TimeFormattingTests {
    @Test func hoursMinutesFormat() {
        #expect(TimeFormatting.hoursMinutes(88) == "1h 28m")
        #expect(TimeFormatting.hoursMinutes(458) == "7h 38m")
        #expect(TimeFormatting.hoursMinutes(24) == "0h 24m")
    }
}
