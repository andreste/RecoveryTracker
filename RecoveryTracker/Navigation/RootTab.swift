import Foundation

enum RootTab: CaseIterable, Hashable {
    case today
    case trends
    case training
    case settings

    var title: String {
        switch self {
        case .today:    return "Today"
        case .trends:   return "Trends"
        case .training: return "Training"
        case .settings: return "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today:    return "house"
        case .trends:   return "chart.bar"
        case .training: return "figure.strengthtraining.traditional"
        case .settings: return "gearshape"
        }
    }
}
