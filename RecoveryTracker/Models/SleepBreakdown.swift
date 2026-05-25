import Foundation

struct SleepBreakdown: Codable, Equatable {
    enum Stage: String, Codable, CaseIterable {
        case deep, rem, core, awake

        var displayName: String {
            switch self {
            case .deep:  return "Deep"
            case .rem:   return "REM"
            case .core:  return "Core"
            case .awake: return "Awake"
            }
        }
    }

    let deepMinutes: Int
    let remMinutes: Int
    let coreMinutes: Int
    let awakeMinutes: Int

    var totalInBedMinutes: Int { deepMinutes + remMinutes + coreMinutes + awakeMinutes }
    var asleepMinutes: Int { totalInBedMinutes - awakeMinutes }

    func minutes(for stage: Stage) -> Int {
        switch stage {
        case .deep:  return deepMinutes
        case .rem:   return remMinutes
        case .core:  return coreMinutes
        case .awake: return awakeMinutes
        }
    }

    func percentage(for stage: Stage) -> Int {
        guard totalInBedMinutes > 0 else { return 0 }
        return Int((Double(minutes(for: stage)) / Double(totalInBedMinutes) * 100).rounded())
    }
}
