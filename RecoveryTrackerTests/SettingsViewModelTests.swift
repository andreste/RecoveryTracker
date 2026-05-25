import Testing
import Foundation
@testable import RecoveryTracker

struct SettingsViewModelTests {

    /// Fresh, isolated UserDefaults suite that does not pollute standard defaults.
    private func makeDefaults() -> UserDefaults {
        let suite = "SettingsViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func defaultTogglesOnFirstRun() {
        let vm = SettingsViewModel(defaults: makeDefaults())
        #expect(vm.dailyReadinessOn == true)
        #expect(vm.bedtimeReminderOn == true)
        #expect(vm.recoveryInsightsOn == false)
    }

    @Test func defaultTrainingGoalOnFirstRun() {
        let vm = SettingsViewModel(defaults: makeDefaults())
        #expect(vm.trainingGoal == .marathon)
    }

    @Test func togglingNotificationPersistsAcrossInstances() {
        let defaults = makeDefaults()
        let vm = SettingsViewModel(defaults: defaults)
        vm.recoveryInsightsOn = true
        vm.dailyReadinessOn = false

        let reloaded = SettingsViewModel(defaults: defaults)
        #expect(reloaded.recoveryInsightsOn == true)
        #expect(reloaded.dailyReadinessOn == false)
        #expect(reloaded.bedtimeReminderOn == true)
    }

    @Test func selectingTrainingGoalPersistsAcrossInstances() {
        let defaults = makeDefaults()
        let vm = SettingsViewModel(defaults: defaults)
        vm.trainingGoal = .tenK

        let reloaded = SettingsViewModel(defaults: defaults)
        #expect(reloaded.trainingGoal == .tenK)
    }
}
