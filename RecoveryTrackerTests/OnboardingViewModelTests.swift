import Testing
import Foundation
@testable import RecoveryTracker

@MainActor
struct OnboardingViewModelTests {

    /// Fresh, isolated UserDefaults suite that does not pollute standard defaults.
    private func makeDefaults() -> UserDefaults {
        let suite = "OnboardingViewModelTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    /// Records calls to `requestAuthorization()`; all reads return empty/nil.
    final class MockHealthProvider: HealthDataProviding {
        private(set) var requestAuthorizationCallCount = 0

        var isAuthorized: Bool { get async { false } }

        func requestAuthorization() async throws -> HealthAuthorizationStatus {
            requestAuthorizationCallCount += 1
            return .authorized
        }

        func latestHRV() async -> HealthSample? { nil }
        func hrvSeries(days: Int) async -> [HealthSample] { [] }
        func latestRestingHeartRate() async -> HealthSample? { nil }
        func restingHeartRateSeries(days: Int) async -> [HealthSample] { [] }
        func lastNightSleep() async -> SleepBreakdown? { nil }
        func averageSleep(days: Int) async -> SleepBreakdown? { nil }
        func recentWorkouts(limit: Int) async -> [Workout] { [] }
        func trainingLoad(for date: Date) async -> Int? { nil }
    }

    private func makeViewModel(
        defaults: UserDefaults? = nil,
        health: MockHealthProvider = MockHealthProvider()
    ) -> OnboardingViewModel {
        OnboardingViewModel(health: health, defaults: defaults ?? makeDefaults())
    }

    @Test func initialStateIsStepOneAndIncomplete() {
        let vm = makeViewModel()
        #expect(vm.step == 1)
        #expect(vm.selectedDiscipline == nil)
        #expect(vm.onboardingComplete == false)
    }

    @Test func selectingDisciplineUpdatesState() {
        let vm = makeViewModel()
        vm.selectDiscipline(.cycling)
        #expect(vm.selectedDiscipline == .cycling)
    }

    @Test func advanceMovesToStepTwo() {
        let vm = makeViewModel()
        vm.selectDiscipline(.running)
        vm.advance()
        #expect(vm.step == 2)
    }

    @Test func backReturnsToStepOne() {
        let vm = makeViewModel()
        vm.advance()
        #expect(vm.step == 2)
        vm.back()
        #expect(vm.step == 1)
    }

    @Test func completeSetsAndPersistsFlag() {
        let defaults = makeDefaults()
        let vm = makeViewModel(defaults: defaults)
        vm.complete()
        #expect(vm.onboardingComplete == true)

        let reloaded = makeViewModel(defaults: defaults)
        #expect(reloaded.onboardingComplete == true)
    }

    @Test func skipSetsAndPersistsFlag() {
        let defaults = makeDefaults()
        let vm = makeViewModel(defaults: defaults)
        vm.skip()
        #expect(vm.onboardingComplete == true)

        let reloaded = makeViewModel(defaults: defaults)
        #expect(reloaded.onboardingComplete == true)
    }

    @Test func selectedDisciplinePersistsAcrossInstances() {
        let defaults = makeDefaults()
        let vm = makeViewModel(defaults: defaults)
        vm.selectDiscipline(.triathlon)

        let reloaded = makeViewModel(defaults: defaults)
        #expect(reloaded.selectedDiscipline == .triathlon)
    }

    @Test func connectHealthRequestsAuthorizationThenCompletes() async {
        let health = MockHealthProvider()
        let vm = makeViewModel(health: health)
        await vm.connectHealth()
        #expect(health.requestAuthorizationCallCount == 1)
        #expect(vm.onboardingComplete == true)
    }
}
