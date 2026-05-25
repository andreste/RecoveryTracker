import Foundation
import Combine

/// Holds the user-mutable Settings state and persists it to UserDefaults.
/// Inject a custom `UserDefaults` (e.g. an isolated test suite) via the initializer.
final class SettingsViewModel: ObservableObject {

    private enum Key {
        static let dailyReadiness   = "settings.dailyReadinessOn"
        static let bedtimeReminder  = "settings.bedtimeReminderOn"
        static let recoveryInsights = "settings.recoveryInsightsOn"
        static let trainingGoal     = "settings.trainingGoal"
    }

    private let defaults: UserDefaults

    @Published var dailyReadinessOn: Bool {
        didSet { defaults.set(dailyReadinessOn, forKey: Key.dailyReadiness) }
    }

    @Published var bedtimeReminderOn: Bool {
        didSet { defaults.set(bedtimeReminderOn, forKey: Key.bedtimeReminder) }
    }

    @Published var recoveryInsightsOn: Bool {
        didSet { defaults.set(recoveryInsightsOn, forKey: Key.recoveryInsights) }
    }

    @Published var trainingGoal: TrainingGoal {
        didSet { defaults.set(trainingGoal.rawValue, forKey: Key.trainingGoal) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.dailyReadinessOn   = defaults.object(forKey: Key.dailyReadiness) as? Bool ?? true
        self.bedtimeReminderOn  = defaults.object(forKey: Key.bedtimeReminder) as? Bool ?? true
        self.recoveryInsightsOn = defaults.object(forKey: Key.recoveryInsights) as? Bool ?? false
        self.trainingGoal = (defaults.string(forKey: Key.trainingGoal)
            .flatMap(TrainingGoal.init(rawValue:))) ?? .marathon
    }
}
