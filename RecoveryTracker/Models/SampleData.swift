import Foundation

// Preview/fixture data mirroring the design mockups. DEBUG-only so it never
// ships in release builds.
#if DEBUG
extension ReadinessScore {
    static let sample = ReadinessScore(value: 78, baselineDelta: 8)
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
