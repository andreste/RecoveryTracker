import Foundation

// Pure, deterministic insight + correlation engine. No HealthKit, no SwiftUI —
// it feeds both the Today screen's daily Insight and the Trends screen's
// auto-detected Correlations from the same recent metric series.
//
// INPUT SHAPE
// Four parallel arrays of daily values, chronological / most-recent-LAST.
// The final element of each array is "today". Arrays may differ in length;
// each computation uses only its own (or the pair's common) trailing window.
//
// DAILY INSIGHT (deterministic rules)
// The headline is driven by the two strongest recovery signals — HRV and
// resting HR — using each metric's short-window average vs the window before
// it (percent change):
//   • HRV up ≥ THRESHOLD and RHR not worsening  → .positive
//   • HRV down ≥ THRESHOLD, or RHR up ≥ THRESHOLD → .caution
//   • otherwise                                  → .neutral
// The computed HRV percentage change is rendered into the body copy.
//
// CORRELATIONS
// Pearson r is computed for a fixed set of metric pairs over their common
// trailing window, ranked by |r|, and the strongest few returned.
enum InsightEngine {

    struct Inputs {
        let hrv: [Double]
        let restingHR: [Double]
        let sleepQuality: [Double]
        let trainingLoad: [Double]
    }

    // Window used for short-vs-prior trend comparison.
    private static let trendWindow = 7
    // Minimum percent change (as a fraction) to count as a real trend.
    private static let trendThreshold = 0.03
    // Most correlations returned to the Trends screen.
    private static let maxCorrelations = 3

    // MARK: - Daily insight

    static func dailyInsight(from inputs: Inputs) -> Insight {
        let hrvChange = percentChange(inputs.hrv)
        let rhrChange = percentChange(inputs.restingHR)

        // No usable trend data → neutral.
        guard let hrvChange = hrvChange else {
            return neutralInsight()
        }

        let hrvRising  = hrvChange >= trendThreshold
        let hrvFalling = hrvChange <= -trendThreshold
        let rhrRising  = (rhrChange ?? 0) >= trendThreshold

        let hrvPercent = Int((abs(hrvChange) * 100).rounded())
        let rhrPercent = Int((abs(rhrChange ?? 0) * 100).rounded())

        if hrvRising && !rhrRising {
            return Insight(
                title: "HRV trending up",
                body: "HRV is trending up \(hrvPercent)% this week — your body's adapting to the higher mileage.",
                recommendation: "Consider a quality session today: tempo intervals or a moderate-long run would be well-tolerated.",
                sentiment: .positive
            )
        }

        if hrvFalling {
            return Insight(
                title: "HRV trending down",
                body: "HRV is down \(hrvPercent)% this week — a sign your recovery is lagging the load.",
                recommendation: "Prioritise rest today: keep it easy, hydrate, and aim for an early night.",
                sentiment: .caution
            )
        }

        if rhrRising {
            return Insight(
                title: "Resting HR climbing",
                body: "Resting heart rate is up \(rhrPercent)% this week — often an early fatigue signal.",
                recommendation: "Back off intensity for a day or two and let your baseline settle.",
                sentiment: .caution
            )
        }

        return neutralInsight()
    }

    private static func neutralInsight() -> Insight {
        Insight(
            title: "Holding steady",
            body: "Your key metrics are stable this week — no significant trend either way.",
            recommendation: "Stick to your plan; consistency is doing its job.",
            sentiment: .neutral
        )
    }

    // MARK: - Correlations

    static func correlations(from inputs: Inputs) -> [Correlation] {
        // sleep → next-day HRV: pair each night's sleep with the FOLLOWING
        // day's HRV, so drop today's sleep and yesterday's HRV to align.
        let sleepToNextHRV = pearson(
            Array(inputs.sleepQuality.dropLast()),
            Array(inputs.hrv.dropFirst())
        )

        let candidates: [Correlation] = [
            Correlation(
                xLabel: "Sleep quality",
                yLabel: "Next-day HRV",
                r: sleepToNextHRV,
                note: note(for: sleepToNextHRV,
                           positive: "Better sleep tends to lift your HRV the next morning.",
                           negative: "Better sleep is tracking with lower next-day HRV — worth a closer look.")
            ),
            Correlation(
                xLabel: "Training load",
                yLabel: "Resting HR",
                r: pearson(inputs.trainingLoad, inputs.restingHR),
                note: note(for: pearson(inputs.trainingLoad, inputs.restingHR),
                           positive: "Heavier training days push your resting heart rate up.",
                           negative: "Heavier training is tracking with a lower resting heart rate.")
            ),
            Correlation(
                xLabel: "Sleep quality",
                yLabel: "Resting HR",
                r: pearson(inputs.sleepQuality, inputs.restingHR),
                note: note(for: pearson(inputs.sleepQuality, inputs.restingHR),
                           positive: "Better sleep is tracking with a higher resting heart rate — unusual; keep an eye on it.",
                           negative: "Better sleep tends to bring your resting heart rate down.")
            )
        ]

        return candidates
            .filter { $0.r != 0 }
            .sorted { abs($0.r) > abs($1.r) }
            .prefix(maxCorrelations)
            .map { $0 }
    }

    private static func note(for r: Double, positive: String, negative: String) -> String {
        r >= 0 ? positive : negative
    }

    // MARK: - Trend math

    // Percent change of a metric's recent short window vs the window before it.
    // Returns nil when there isn't enough history or the prior mean is zero.
    private static func percentChange(_ series: [Double]) -> Double? {
        let usable = series.filter { $0.isFinite }
        guard usable.count >= 2 else { return nil }

        let window = min(trendWindow, usable.count / 2)
        guard window >= 1 else { return nil }

        let recent = Array(usable.suffix(window))
        let prior = Array(usable.dropLast(window).suffix(window))
        guard let recentMean = mean(recent), let priorMean = mean(prior), priorMean != 0 else { return nil }

        return (recentMean - priorMean) / priorMean
    }

    // MARK: - Pearson correlation

    // Pearson r over the common trailing window of two series. Returns 0 when
    // fewer than 2 aligned points or either series has zero variance.
    static func pearson(_ a: [Double], _ b: [Double]) -> Double {
        let count = min(a.count, b.count)
        guard count >= 2 else { return 0 }

        let x = Array(a.suffix(count))
        let y = Array(b.suffix(count))

        guard let meanX = mean(x), let meanY = mean(y) else { return 0 }

        var covariance = 0.0
        var varianceX = 0.0
        var varianceY = 0.0
        for i in 0..<count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            covariance += dx * dy
            varianceX += dx * dx
            varianceY += dy * dy
        }

        let denominator = (varianceX * varianceY).squareRoot()
        guard denominator > 0 else { return 0 }

        let r = covariance / denominator
        guard r.isFinite else { return 0 }
        return r
    }

    private static func mean(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }
}
