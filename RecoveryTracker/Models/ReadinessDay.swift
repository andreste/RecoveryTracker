import Foundation

// One point in the 7-day readiness history series used by the Today bar chart.
struct ReadinessDay: Codable, Equatable, Identifiable {
    let date: Date
    let score: Int

    var id: Date { date }
}
