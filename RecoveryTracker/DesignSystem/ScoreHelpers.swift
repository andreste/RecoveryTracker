import SwiftUI

enum ScoreHelpers {
    // Score → brand color
    // ≥75: teal (Good), 55–74: amber (Moderate), <55: coral (Poor)
    static func color(for score: Int) -> Color {
        if score >= 75 { return .rtTeal }
        if score >= 55 { return .rtAmber }
        return .rtCoral
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
