import Foundation
import Combine

/// Drives the Trends screen. Pulls the 28-day HRV and training-load series, the
/// 7-day average sleep breakdown, and the auto-detected correlations (via
/// `InsightEngine`) from the injected `HealthDataProviding`.
///
/// Because HealthKit returns nothing in the simulator, a provider that yields no
/// usable series falls back to the DEBUG sample fixtures so the screen and
/// previews still render.
@MainActor
final class TrendsViewModel: ObservableObject {

    private let health: HealthDataProviding

    // Trailing window the dual-line chart plots.
    static let chartDays = 28
    // Window for the sleep breakdown average.
    private static let sleepDays = 7

    @Published private(set) var hrvSeries: [Double] = []
    @Published private(set) var loadSeries: [Double] = []
    @Published private(set) var sleep: SleepBreakdown = .placeholder
    @Published private(set) var correlations: [Correlation] = []

    var hrvAverage: Double { Self.average(hrvSeries) }
    var loadAverage: Double { Self.average(loadSeries) }

    init(health: HealthDataProviding = HealthKitService()) {
        self.health = health
    }

    func load() async {
        let inputs = await Self.inputs(from: health)
        async let sleepAverage = health.averageSleep(days: Self.sleepDays)
        let breakdown = await sleepAverage

        // No usable history → fall back to sample data for the simulator/previews.
        guard Self.hasUsableData(inputs) else {
            applySampleData()
            return
        }

        hrvSeries = inputs.hrv
        loadSeries = inputs.trainingLoad
        sleep = breakdown ?? .sampleOrPlaceholder
        correlations = InsightEngine.correlations(from: inputs)
    }

    // MARK: - Provider → engine inputs

    /// Assembles the four parallel daily series (chronological, most-recent-LAST)
    /// the InsightEngine consumes over the chart window. Sleep has no per-day
    /// series on the provider, so a flat quality series is derived from the
    /// average breakdown — mirroring `TodayViewModel`.
    static func inputs(from health: HealthDataProviding) async -> InsightEngine.Inputs {
        async let hrvSamples = health.hrvSeries(days: chartDays)
        async let rhrSamples = health.restingHeartRateSeries(days: chartDays)
        async let average = health.averageSleep(days: sleepDays)

        let hrv = (await hrvSamples).map(\.value)
        let restingHR = (await rhrSamples).map(\.value)
        let trainingLoad = await loadSeries(from: health, days: chartDays)

        let sleepQuality: [Double]
        if let breakdown = await average {
            sleepQuality = Array(repeating: sleepScore(for: breakdown), count: max(hrv.count, 1))
        } else {
            sleepQuality = []
        }

        return InsightEngine.Inputs(
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
    private static func sleepScore(for breakdown: SleepBreakdown) -> Double {
        guard breakdown.totalInBedMinutes > 0 else { return 0 }
        return Double(breakdown.asleepMinutes) / Double(breakdown.totalInBedMinutes) * 100
    }

    private static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    // MARK: - Fallback

    /// The chart needs both lines to render meaningfully.
    private static func hasUsableData(_ inputs: InsightEngine.Inputs) -> Bool {
        !inputs.hrv.isEmpty && !inputs.trainingLoad.isEmpty
    }

    private func applySampleData() {
        hrvSeries = Self.sampleHRV
        loadSeries = Self.sampleLoad
        sleep = .sampleOrPlaceholder
        correlations = Self.sampleCorrelations
    }

    // MARK: - Sample / placeholder bridging
    //
    // Sample fixtures are DEBUG-only; release builds use neutral placeholders so
    // the VM compiles and never crashes when HealthKit yields nothing.

    private static var sampleHRV: [Double] {
        #if DEBUG
        return TrendsSample.hrv
        #else
        return Array(repeating: 60, count: chartDays)
        #endif
    }

    private static var sampleLoad: [Double] {
        #if DEBUG
        return TrendsSample.load
        #else
        return Array(repeating: 280, count: chartDays)
        #endif
    }

    private static var sampleCorrelations: [Correlation] {
        #if DEBUG
        return Correlation.samples
        #else
        return InsightEngine.correlations(
            from: InsightEngine.Inputs(hrv: sampleHRV, restingHR: [],
                                       sleepQuality: [], trainingLoad: sampleLoad)
        )
        #endif
    }
}

// MARK: - SleepBreakdown placeholder bridging

private extension SleepBreakdown {
    static let placeholder = SleepBreakdown(deepMinutes: 0, remMinutes: 0,
                                            coreMinutes: 0, awakeMinutes: 0)
    static var sampleOrPlaceholder: SleepBreakdown {
        #if DEBUG
        return .sample
        #else
        return .placeholder
        #endif
    }
}
