import SwiftUI

// The athlete's primary sport, chosen during onboarding. Distinct from
// `Sport` (a workout's activity type) — disciplines include Triathlon, which
// is not a single workout type.
enum Discipline: String, Codable, CaseIterable, Identifiable {
    case running, cycling, strength, triathlon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .running:   return "Running"
        case .cycling:   return "Cycling"
        case .strength:  return "Strength"
        case .triathlon: return "Triathlon"
        }
    }

    var subtitle: String {
        switch self {
        case .running:   return "Road · trail"
        case .cycling:   return "Road · gravel"
        case .strength:  return "Gym · home"
        case .triathlon: return "Swim · bike · run"
        }
    }

    var symbolName: String {
        switch self {
        case .running:   return "figure.run"
        case .cycling:   return "bicycle"
        case .strength:  return "dumbbell.fill"
        case .triathlon: return "figure.pool.swim"
        }
    }

    var accentColor: Color {
        switch self {
        case .running:   return .rtTeal
        case .cycling:   return .rtBlue
        case .strength:  return .rtAmber
        case .triathlon: return .rtPurple
        }
    }
}
