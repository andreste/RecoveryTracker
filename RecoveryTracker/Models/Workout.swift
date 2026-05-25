import Foundation

// A single completed workout pulled from HealthKit.
// Reuses the existing `Sport` (activity type) and `RecoveryCost` enums.
struct Workout: Identifiable, Equatable {
    let id: UUID
    let sport: Sport
    let title: String
    let date: Date
    let durationSeconds: Int
    let primaryStat: String   // e.g. "8.2 km · 6:36/km" or "5 sets · 18 reps avg"
    let recoveryCost: RecoveryCost

    init(id: UUID = UUID(), sport: Sport, title: String, date: Date,
         durationSeconds: Int, primaryStat: String, recoveryCost: RecoveryCost) {
        self.id = id
        self.sport = sport
        self.title = title
        self.date = date
        self.durationSeconds = durationSeconds
        self.primaryStat = primaryStat
        self.recoveryCost = recoveryCost
    }

    var durationFormatted: String { TimeFormatting.clockDuration(durationSeconds) }
}
