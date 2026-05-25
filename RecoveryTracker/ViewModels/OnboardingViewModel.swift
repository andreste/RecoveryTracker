import Foundation
import Combine

/// Drives the two-step first-run onboarding (sport selection + HealthKit).
/// Persists the chosen `Discipline` and an `onboardingComplete` flag so the
/// app can gate the main UI behind first-launch onboarding.
///
/// Inject a `HealthDataProviding` (mock in tests, `HealthKitService` in the
/// app) and a custom `UserDefaults` (an isolated test suite) via the initializer.
@MainActor
final class OnboardingViewModel: ObservableObject {

    private enum Key {
        static let discipline = "onboarding.discipline"
        static let complete   = "onboarding.complete"
    }

    private let health: HealthDataProviding
    private let defaults: UserDefaults

    /// Current step: 1 = sport selection, 2 = HealthKit permission.
    @Published private(set) var step: Int = 1

    @Published private(set) var selectedDiscipline: Discipline? {
        didSet { defaults.set(selectedDiscipline?.rawValue, forKey: Key.discipline) }
    }

    @Published private(set) var onboardingComplete: Bool {
        didSet { defaults.set(onboardingComplete, forKey: Key.complete) }
    }

    init(health: HealthDataProviding, defaults: UserDefaults = .standard) {
        self.health = health
        self.defaults = defaults
        self.selectedDiscipline = defaults.string(forKey: Key.discipline)
            .flatMap(Discipline.init(rawValue:))
        self.onboardingComplete = defaults.bool(forKey: Key.complete)
    }

    func selectDiscipline(_ discipline: Discipline) {
        selectedDiscipline = discipline
    }

    func advance() {
        step = 2
    }

    func back() {
        step = 1
    }

    /// Requests HealthKit read access, then completes onboarding regardless of
    /// the granted status (the user can manage permissions later in Settings).
    func connectHealth() async {
        _ = try? await health.requestAuthorization()
        complete()
    }

    func skip() {
        complete()
    }

    func complete() {
        onboardingComplete = true
    }
}
