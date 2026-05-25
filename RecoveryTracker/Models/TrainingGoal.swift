import Foundation

enum TrainingGoal: String, Codable, CaseIterable, Identifiable {
    case marathon, halfMarathon, tenK, generalFitness

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .marathon:       return "Marathon"
        case .halfMarathon:   return "Half marathon"
        case .tenK:           return "10K"
        case .generalFitness: return "General fitness"
        }
    }
}
