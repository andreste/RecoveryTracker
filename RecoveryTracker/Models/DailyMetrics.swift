import Foundation

// A single metric's change vs its 7-day average.
// `goodUp` records whether an increase is a positive outcome (HRV up = good,
// resting HR up = bad), so the UI can color it without re-deriving direction.
struct MetricDelta: Codable, Equatable {
    let value: Double
    let goodUp: Bool

    var isNeutral: Bool { value == 0 }

    var isImprovement: Bool {
        guard value != 0 else { return false }
        return goodUp ? value > 0 : value < 0
    }
}

struct Metric: Codable, Equatable, Identifiable {
    enum Kind: String, Codable {
        case hrv, restingHR, sleepQuality, trainingLoad

        var displayName: String {
            switch self {
            case .hrv:          return "HRV"
            case .restingHR:    return "Resting HR"
            case .sleepQuality: return "Sleep quality"
            case .trainingLoad: return "Training load"
            }
        }
    }

    let kind: Kind
    let value: Double
    let unit: String
    let delta: MetricDelta

    var id: String { kind.rawValue }
}

// The four headline metrics shown in the Today 2×2 grid.
struct DailyMetrics: Codable, Equatable {
    let hrv: Metric
    let restingHR: Metric
    let sleepQuality: Metric
    let trainingLoad: Metric

    var all: [Metric] { [hrv, restingHR, sleepQuality, trainingLoad] }
}
