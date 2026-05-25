import Foundation
import Combine
import SwiftUI

/// One day's training-load bar in the weekly chart. A `isRest` day (load 0)
/// renders as a dashed placeholder rather than a solid bar.
struct DayLoad: Identifiable {
    let id = UUID()
    let day: String   // single weekday letter, e.g. "M"
    let load: Int     // training load in "au"
    var isRest: Bool { load == 0 }
}

/// Drives the Training tab: recent workouts (mapped to `WorkoutRowData`) and the
/// weekly per-day training load. Inject a `HealthDataProviding` (mock in tests,
/// `HealthKitService` in the app). Because HealthKit returns nothing in the
/// simulator, an empty provider result falls back to the DEBUG sample workouts
/// so the screen and previews still render.
@MainActor
final class TrainingViewModel: ObservableObject {

    private let health: HealthDataProviding
    private let workoutLimit = 14
    private let calendar = Calendar.current

    @Published private(set) var workouts: [WorkoutRowData] = []
    @Published private(set) var weeklyLoad: [DayLoad] = []
    @Published private(set) var totalLoad: Int = 0
    @Published private(set) var weekStart: Date = Date()

    /// Status pill copy + tint, bucketed off the week's total load.
    var status: (label: String, color: Color) {
        switch totalLoad {
        case ..<1200:  return ("LIGHT", .rtTeal)
        case ..<2600:  return ("OPTIMAL", .rtTeal)
        default:       return ("HIGH", .rtCoral)
        }
    }

    /// "Week of May 18" subtitle.
    var weekSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Week of \(formatter.string(from: weekStart))"
    }

    var totalLoadString: String { Self.grouped(totalLoad) }

    init(health: HealthDataProviding = HealthKitService()) {
        self.health = health
    }

    func load() async {
        var fetched = await health.recentWorkouts(limit: workoutLimit)

        // Simulator / no-data fallback so the screen renders during development.
        if fetched.isEmpty {
            fetched = Self.sampleWorkouts()
        }

        let start = Self.startOfWeek(for: Date(), calendar: calendar)
        weekStart = start
        let week = Self.weeklyLoad(from: fetched, weekStart: start, calendar: calendar)

        weeklyLoad = week
        totalLoad = week.map(\.load).reduce(0, +)
        workouts = fetched.map { Self.rowData(for: $0, calendar: calendar) }
    }

    // MARK: - Pure mapping / aggregation helpers

    /// Maps a `Workout` into the row model `WorkoutRow` renders.
    static func rowData(for workout: Workout, calendar: Calendar = .current) -> WorkoutRowData {
        WorkoutRowData(
            sport: workout.sport,
            title: workout.title,
            day: dayLabel(for: workout.date, relativeTo: Date(), calendar: calendar),
            duration: workout.durationFormatted,
            detail: workout.primaryStat,
            cost: workout.recoveryCost
        )
    }

    /// Relative day label: "Today" / "Yesterday" / a short weekday ("Wed").
    static func dayLabel(for date: Date, relativeTo reference: Date,
                         calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: reference) { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: reference),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Yesterday"
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale.current
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    /// Per-workout training load in "au". Derived from duration scaled by the
    /// recovery cost, since `Workout` carries no raw energy. Used to size the
    /// weekly bars; the bucketing thresholds below color them.
    static func load(for workout: Workout) -> Int {
        let minutes = Double(workout.durationSeconds) / 60.0
        let multiplier: Double
        switch workout.recoveryCost {
        case .low:    multiplier = 4
        case .medium: multiplier = 6
        case .high:   multiplier = 9
        }
        return Int((minutes * multiplier).rounded())
    }

    /// Load → color bucket. > 400 high (coral), > 250 medium (amber), else low (teal).
    static func loadLevel(for load: Int) -> RecoveryCost {
        if load > 400 { return .high }
        if load > 250 { return .medium }
        return .low
    }

    /// Aggregates workouts into seven `DayLoad`s, Mon–Sun starting at `weekStart`.
    /// Workouts outside the week are ignored; days with no workouts are rest days.
    static func weeklyLoad(from workouts: [Workout], weekStart: Date,
                           calendar: Calendar = .current) -> [DayLoad] {
        let letters = ["M", "T", "W", "T", "F", "S", "S"]
        let start = calendar.startOfDay(for: weekStart)

        return (0..<7).map { offset in
            let dayStart = calendar.date(byAdding: .day, value: offset, to: start)!
            let total = workouts
                .filter { calendar.isDate($0.date, inSameDayAs: dayStart) }
                .map(load(for:))
                .reduce(0, +)
            return DayLoad(day: letters[offset], load: total)
        }
    }

    /// Most recent Monday (start of the current week) at midnight.
    static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        // Calendar.weekday: Sunday = 1 ... Saturday = 7. Map to Monday-based offset.
        let weekday = calendar.component(.weekday, from: startOfDay)
        let offset = (weekday + 5) % 7   // Mon → 0, Tue → 1, ... Sun → 6
        return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
    }

    /// Integer with thousands separators, e.g. 1920 → "1,920".
    static func grouped(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func sampleWorkouts() -> [Workout] {
        #if DEBUG
        return Workout.samples
        #else
        return []
        #endif
    }
}
