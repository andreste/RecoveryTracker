import SwiftUI

// Coarse readiness tier used for color coding (3 bands).
// Distinct from the 5-tier status/advice label below.
enum ScoreBand {
    case poor, moderate, good
}

enum ScoreHelpers {
    // Score → band
    // ≥75: good, 55–74: moderate, <55: poor
    static func band(for score: Int) -> ScoreBand {
        if score >= 75 { return .good }
        if score >= 55 { return .moderate }
        return .poor
    }

    // Score → brand color (teal / amber / coral)
    static func color(for score: Int) -> Color {
        switch band(for: score) {
        case .good:     return .rtTeal
        case .moderate: return .rtAmber
        case .poor:     return .rtCoral
        }
    }

    // Score → (status, advice) pair
    static func label(for score: Int) -> (status: String, advice: String) {
        switch score {
        case 85...100: return ("Optimal",  "Push hard today")
        case 75..<85:  return ("Good",     "Train normally")
        case 60..<75:  return ("Moderate", "Aerobic work only")
        case 45..<60:  return ("Caution",  "Keep it easy")
        default:       return ("Poor",     "Prioritize rest")
        }
    }
}
