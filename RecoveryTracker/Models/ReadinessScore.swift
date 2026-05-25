import Foundation

// Daily readiness score (0–100) plus its movement against the rolling baseline.
struct ReadinessScore: Codable, Equatable {
    let value: Int
    let baselineDelta: Int

    var band: ScoreBand { ScoreHelpers.band(for: value) }
    var status: String { ScoreHelpers.label(for: value).status }
    var advice: String { ScoreHelpers.label(for: value).advice }

    var baselineDeltaIsPositive: Bool { baselineDelta >= 0 }

    var baselineDeltaString: String {
        baselineDelta > 0 ? "+\(baselineDelta)" : "\(baselineDelta)"
    }
}
