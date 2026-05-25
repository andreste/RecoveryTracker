import Foundation
import Combine

/// Drives the Today (home) screen. Pulls the four daily metric series from the
/// injected `HealthDataProviding`, feeds them through `ReadinessEngine` and
/// `InsightEngine`, and publishes the readiness score, headline metrics, 7-day
/// history, and the daily insight.
///
/// Because HealthKit returns nothing in the simulator, a provider that yields no
/// usable series falls back to the DEBUG sample fixtures so the screen and
/// previews still render.
@MainActor
final class TodayViewModel: ObservableObject {

    private let health: HealthDataProviding

    // History pulled to build the rolling 30-day baseline the engines expect.
    private static let historyDays = 30

    @Published private(set) var score: ReadinessScore = .placeholder
    @Published private(set) var metrics: DailyMetrics = .placeholder
    @Published private(set) var history: [ReadinessDay] = []
    @Published private(set) var insight: Insight = .placeholder

    /// "Sunday · May 24" — today's date for the header subtitle.
    var dateSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE · MMM d"
        return formatter.string(from: Date())
    }

    init(health: HealthDataProviding = HealthKitService()) {
        self.health = health
    }

    func load() async {
        let inputs = await Self.inputs(from: health)

        // No usable history → fall back to sample data for the simulator/previews.
        guard Self.hasUsableData(inputs) else {
            applySampleData()
            return
        }

        let result = ReadinessEngine.evaluate(inputs)
        let dailyInsight = InsightEngine.dailyInsight(
            from: InsightEngine.Inputs(hrv: inputs.hrv, restingHR: inputs.restingHR,
                                       sleepQuality: inputs.sleepQuality,
                                       trainingLoad: inputs.trainingLoad)
        )

        score = result.score
        metrics = result.metrics
        history = result.history
        insight = dailyInsight
    }

    // MARK: - Provider → engine inputs

    /// Assembles the four parallel daily series (chronological, most-recent-LAST)
    /// the engines consume. Sleep has no per-day series on the provider, so we
    /// derive a flat quality series from the latest breakdown.
    static func inputs(from health: HealthDataProviding) async -> ReadinessEngine.Inputs {
        async let hrvSamples = health.hrvSeries(days: historyDays)
        async let rhrSamples = health.restingHeartRateSeries(days: historyDays)
        async let lastNight = health.lastNightSleep()

        let hrv = (await hrvSamples).map(\.value)
        let restingHR = (await rhrSamples).map(\.value)
        let trainingLoad = await loadSeries(from: health, days: historyDays)

        // The provider exposes a single sleep breakdown, not a per-day series.
        // Spread its quality across the same span so the engine has a baseline.
        let sleepQuality: [Double]
        if let breakdown = await lastNight {
            sleepQuality = Array(repeating: sleepScore(for: breakdown), count: max(hrv.count, 1))
        } else {
            sleepQuality = []
        }

        return ReadinessEngine.Inputs(
            hrv: hrv,
            restingHR: restingHR,
            sleepQuality: sleepQuality,
            trainingLoad: trainingLoad
        )
    }

    /// Daily training load (au) for the trailing `days`, chronological / oldest first.
    private static func loadSeries(from health: HealthDataProviding, days: Int,
                                   calendar: Calendar = .current, today: Date = Date()) async -> [Double] {
        let startOfToday = calendar.startOfDay(for: today)
        var values: [Double] = []
        for offset in (0..<days).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { continue }
            if let load = await health.trainingLoad(for: day) {
                values.append(Double(load))
            }
        }
        return values
    }

    /// A 0–100 sleep-quality scalar: time asleep as a percentage of time in bed.
    static func sleepScore(for breakdown: SleepBreakdown) -> Double {
        guard breakdown.totalInBedMinutes > 0 else { return 0 }
        return Double(breakdown.asleepMinutes) / Double(breakdown.totalInBedMinutes) * 100
    }

    // MARK: - Fallback

    /// At least one metric must carry real data for the engines to mean anything.
    private static func hasUsableData(_ inputs: ReadinessEngine.Inputs) -> Bool {
        !inputs.hrv.isEmpty || !inputs.restingHR.isEmpty
            || !inputs.sleepQuality.isEmpty || !inputs.trainingLoad.isEmpty
    }

    private func applySampleData() {
        score = .sampleOrPlaceholder
        metrics = .sampleOrPlaceholder
        insight = .sampleOrPlaceholder
        history = Self.sampleOrPlaceholderHistory
    }

    private static var sampleOrPlaceholderHistory: [ReadinessDay] {
        #if DEBUG
        return ReadinessDay.sampleHistory
        #else
        // Neutral 7-day history so the chart still renders 7 bars in release.
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
            return ReadinessDay(date: date, score: 50)
        }
        #endif
    }
}

// MARK: - Sample / placeholder bridging
//
// Sample fixtures are DEBUG-only; release builds use neutral placeholders so the
// VM compiles and never crashes when HealthKit yields nothing.

private extension ReadinessScore {
    static let placeholder = ReadinessScore(value: 50, baselineDelta: 0)
    static var sampleOrPlaceholder: ReadinessScore {
        #if DEBUG
        return .sample
        #else
        return .placeholder
        #endif
    }
}

private extension DailyMetrics {
    static let placeholder = DailyMetrics(
        hrv: Metric(kind: .hrv, value: 0, unit: "ms", delta: MetricDelta(value: 0, goodUp: true)),
        restingHR: Metric(kind: .restingHR, value: 0, unit: "bpm", delta: MetricDelta(value: 0, goodUp: false)),
        sleepQuality: Metric(kind: .sleepQuality, value: 0, unit: "%", delta: MetricDelta(value: 0, goodUp: true)),
        trainingLoad: Metric(kind: .trainingLoad, value: 0, unit: "au", delta: MetricDelta(value: 0, goodUp: false))
    )
    static var sampleOrPlaceholder: DailyMetrics {
        #if DEBUG
        return .sample
        #else
        return .placeholder
        #endif
    }
}

private extension Insight {
    static let placeholder = Insight(
        title: "Holding steady",
        body: "Your key metrics are stable this week.",
        recommendation: "Stick to your plan.",
        sentiment: .neutral
    )
    static var sampleOrPlaceholder: Insight {
        #if DEBUG
        return .sample
        #else
        return .placeholder
        #endif
    }
}
