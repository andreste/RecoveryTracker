import Foundation

// Pure, deterministic readiness computation. No HealthKit, no SwiftUI — a later
// ticket feeds HealthKitService outputs in. Everything here is unit-testable.
//
// INPUT SHAPE
// Four parallel arrays of daily values, chronological / most-recent-LAST.
// The final element of each array is "today". The values immediately before
// today form the rolling windows:
//   • baseline window = up to 30 days before today (rolling 30-day baseline)
//   • short window    = up to 7 days before today  (per-metric 7-day average)
// Arrays may differ in length; each metric uses its own available history.
//
// SCORING MODEL (deterministic, documented)
// Each metric is normalized against its own 30-day baseline into a 0–100
// sub-score, where 50 means "exactly at baseline":
//
//   relativeDeviation = (today - baseline) / baseline      // signed
//   directional       = goodUp ? relativeDeviation : -relativeDeviation
//   subScore          = clamp(50 + directional * SENSITIVITY, 0, 100)
//
// SENSITIVITY (250) maps a ±20% move from baseline to roughly ±50 points, so a
// metric 20% better than baseline saturates near 100 and 20% worse near 0.
//
// The four sub-scores are combined with fixed weights and clamped to 0–100:
//   HRV 40% · Resting HR 25% · Sleep quality 20% · Training load 15%
// HRV carries the most weight (strongest recovery signal); load the least.
// A perfectly flat history (today == baseline everywhere) scores exactly 50.
enum ReadinessEngine {

    struct Inputs {
        let hrv: [Double]
        let restingHR: [Double]
        let sleepQuality: [Double]
        let trainingLoad: [Double]
    }

    struct Result {
        let score: ReadinessScore
        let metrics: DailyMetrics
        let history: [ReadinessDay]
    }

    // Weighting of each metric's sub-score in the final readiness value.
    private static let weightHRV          = 0.40
    private static let weightRestingHR    = 0.25
    private static let weightSleepQuality = 0.20
    private static let weightTrainingLoad = 0.15

    // Maps relative deviation from baseline to sub-score points.
    private static let sensitivity = 250.0

    private static let baselineWindow = 30
    private static let shortWindow = 7

    static func evaluate(_ inputs: Inputs, calendar: Calendar = .current, today: Date = Date()) -> Result {
        let hrvScore   = subScore(series: inputs.hrv,          goodUp: true)
        let rhrScore   = subScore(series: inputs.restingHR,    goodUp: false)
        let sleepScore = subScore(series: inputs.sleepQuality, goodUp: true)
        let loadScore  = subScore(series: inputs.trainingLoad, goodUp: false)

        let weighted =
            hrvScore   * weightHRV +
            rhrScore   * weightRestingHR +
            sleepScore * weightSleepQuality +
            loadScore  * weightTrainingLoad

        let value = clampScore(weighted)
        let baselineDelta = value - 50 // 50 == sitting exactly on the baseline

        let score = ReadinessScore(value: value, baselineDelta: baselineDelta)

        let metrics = DailyMetrics(
            hrv:          metric(kind: .hrv,          unit: "ms",  series: inputs.hrv,          goodUp: true),
            restingHR:    metric(kind: .restingHR,    unit: "bpm", series: inputs.restingHR,    goodUp: false),
            sleepQuality: metric(kind: .sleepQuality, unit: "%",   series: inputs.sleepQuality, goodUp: true),
            trainingLoad: metric(kind: .trainingLoad, unit: "au",  series: inputs.trainingLoad, goodUp: false)
        )

        let history = buildHistory(inputs, todayScore: value, calendar: calendar, today: today)

        return Result(score: score, metrics: metrics, history: history)
    }

    // MARK: - Per-metric helpers

    // 0–100 sub-score for a metric's most recent value vs its 30-day baseline.
    private static func subScore(series: [Double], goodUp: Bool) -> Double {
        guard let todayValue = series.last else { return 50 }
        let baseline = baselineAverage(series)
        guard baseline != 0 else { return 50 }

        let relativeDeviation = (todayValue - baseline) / baseline
        let directional = goodUp ? relativeDeviation : -relativeDeviation
        return min(max(50 + directional * sensitivity, 0), 100)
    }

    // Mean of up to the 30 days immediately before today; falls back to the
    // whole series (then today's value) when little history exists.
    private static func baselineAverage(_ series: [Double]) -> Double {
        average(window(series, length: baselineWindow))
            ?? average(series)
            ?? (series.last ?? 0)
    }

    private static func metric(kind: Metric.Kind, unit: String, series: [Double], goodUp: Bool) -> Metric {
        let todayValue = series.last ?? 0
        let sevenDayAverage = average(window(series, length: shortWindow)) ?? todayValue
        let delta = MetricDelta(value: todayValue - sevenDayAverage, goodUp: goodUp)
        return Metric(kind: kind, value: todayValue, unit: unit, delta: delta)
    }

    // MARK: - History

    // 7-day readiness series ending today. For each of the last 7 days we treat
    // that day as "today" and compute its score against the same baseline model,
    // so the chart and the headline score stay consistent.
    private static func buildHistory(_ inputs: Inputs, todayScore: Int, calendar: Calendar, today: Date) -> [ReadinessDay] {
        let dayCount = 7
        let startOfToday = calendar.startOfDay(for: today)

        return (0..<dayCount).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
            let score: Int
            if offset == 0 {
                score = todayScore
            } else {
                let weighted =
                    subScore(series: dropping(inputs.hrv, last: offset),          goodUp: true)  * weightHRV +
                    subScore(series: dropping(inputs.restingHR, last: offset),    goodUp: false) * weightRestingHR +
                    subScore(series: dropping(inputs.sleepQuality, last: offset), goodUp: true)  * weightSleepQuality +
                    subScore(series: dropping(inputs.trainingLoad, last: offset), goodUp: false) * weightTrainingLoad
                score = clampScore(weighted)
            }
            return ReadinessDay(date: date, score: score)
        }
    }

    // MARK: - Math utilities

    // Values immediately BEFORE today (the last element), newest first not
    // required — we only average them.
    private static func window(_ series: [Double], length: Int) -> [Double] {
        guard series.count > 1 else { return [] }
        let priorDays = Array(series.dropLast())
        return Array(priorDays.suffix(length))
    }

    // The series as it would have looked `last` days ago (today = element at -last).
    private static func dropping(_ series: [Double], last: Int) -> [Double] {
        guard series.count > last else { return series }
        return Array(series.dropLast(last))
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func clampScore(_ value: Double) -> Int {
        Int(min(max(value.rounded(), 0), 100))
    }
}
