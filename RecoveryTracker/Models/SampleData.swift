import Foundation

// Preview/fixture data mirroring the design mockups. DEBUG-only so it never
// ships in release builds.
#if DEBUG
extension ReadinessScore {
    static let sample = ReadinessScore(value: 78, baselineDelta: 8)
}

extension ReadinessDay {
    // A 7-day readiness history ending today, mirroring the design mockup. Used
    // by the Today bar chart when HealthKit yields nothing (simulator/previews).
    static let sampleHistory: [ReadinessDay] = {
        let scores = [62, 71, 58, 74, 81, 67, 78]
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return scores.enumerated().map { index, score in
            let offset = scores.count - 1 - index
            let date = calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
            return ReadinessDay(date: date, score: score)
        }
    }()
}

extension DailyMetrics {
    static let sample = DailyMetrics(
        hrv: Metric(kind: .hrv, value: 68, unit: "ms",
                    delta: MetricDelta(value: 4, goodUp: true)),
        restingHR: Metric(kind: .restingHR, value: 52, unit: "bpm",
                          delta: MetricDelta(value: -2, goodUp: false)),
        sleepQuality: Metric(kind: .sleepQuality, value: 84, unit: "%",
                             delta: MetricDelta(value: 3, goodUp: true)),
        trainingLoad: Metric(kind: .trainingLoad, value: 312, unit: "au",
                             delta: MetricDelta(value: 18, goodUp: false))
    )
}

extension SleepBreakdown {
    static let sample = SleepBreakdown(deepMinutes: 88, remMinutes: 64,
                                       coreMinutes: 202, awakeMinutes: 24)
}

// 28-day HRV (ms) / training-load (au) fixtures for the Trends dual-line chart,
// mirroring the design mockup. Used when HealthKit yields nothing (simulator).
enum TrendsSample {
    static let hrv: [Double] = [
        62, 58, 60, 64, 66, 63, 59, 55, 52, 58, 62, 64, 68, 70,
        67, 63, 66, 70, 72, 69, 65, 60, 63, 68, 71, 74, 70, 72
    ]
    static let load: [Double] = [
        240, 260, 310, 180, 200, 420, 380, 340, 200, 150, 260, 310, 290, 260,
        200, 420, 440, 360, 260, 200, 300, 460, 420, 360, 260, 180, 260, 310
    ]
    // A flat resting-HR / sleep-quality companion series so the InsightEngine can
    // still compute non-trivial correlations on the sample path.
    static let restingHR: [Double] = [
        54, 56, 53, 52, 51, 55, 57, 58, 59, 56, 54, 53, 52, 51,
        53, 56, 58, 55, 53, 52, 54, 57, 56, 54, 52, 50, 53, 51
    ]
    static let sleepQuality: [Double] = [
        82, 78, 84, 88, 86, 80, 76, 74, 72, 79, 83, 85, 88, 90,
        87, 81, 79, 84, 89, 88, 85, 80, 83, 87, 90, 92, 88, 91
    ]
}

extension Insight {
    static let sample = Insight(
        title: "HRV trending up",
        body: "HRV is trending up 8% this week — your body's adapting to the higher mileage.",
        recommendation: "Consider a quality session today: tempo intervals or a moderate-long run would be well-tolerated.",
        sentiment: .positive
    )
}

extension Correlation {
    static let samples: [Correlation] = [
        Correlation(xLabel: "Sleep quality", yLabel: "Next-day HRV", r: 0.71,
                    note: "Nights above 85% lead to a ~7ms HRV bump the next morning."),
        Correlation(xLabel: "Training load (3-day)", yLabel: "Resting HR", r: 0.58,
                    note: "RHR climbs ~3 bpm when 3-day load exceeds 380 au."),
        Correlation(xLabel: "Alcohol", yLabel: "Deep sleep", r: -0.64,
                    note: "Logged drinks reduced deep sleep by 22 minutes on average.")
    ]
}

extension Workout {
    static let samples: [Workout] = [
        Workout(sport: .run,  title: "Easy aerobic run",      date: daysAgo(0),
                durationSeconds: 3252, primaryStat: "8.2 km · 6:36/km",   recoveryCost: .low),
        Workout(sport: .lift, title: "Lower body — strength", date: daysAgo(1),
                durationSeconds: 2910, primaryStat: "5 sets · 18 reps avg", recoveryCost: .medium),
        Workout(sport: .run,  title: "Tempo intervals",       date: daysAgo(3),
                durationSeconds: 4101, primaryStat: "12.4 km · 4:42 avg",  recoveryCost: .high),
        Workout(sport: .yoga, title: "Mobility & yoga",       date: daysAgo(4),
                durationSeconds: 1920, primaryStat: "zone 1",             recoveryCost: .low),
        Workout(sport: .ride, title: "Recovery spin",         date: daysAgo(5),
                durationSeconds: 2700, primaryStat: "18.4 km · 102 W avg", recoveryCost: .low),
        Workout(sport: .run,  title: "Long run",              date: daysAgo(6),
                durationSeconds: 6128, primaryStat: "21.1 km · 4:51 avg",  recoveryCost: .high)
    ]

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
    }
}
#endif
