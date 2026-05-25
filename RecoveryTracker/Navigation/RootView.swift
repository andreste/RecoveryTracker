import SwiftUI

/// App entry gate: shows `OnboardingView` on first launch and switches to the
/// main `ContentView` (tab bar) once onboarding is complete. The flag lives in
/// `OnboardingViewModel`, persisted to `UserDefaults`, so it survives relaunches.
struct RootView: View {
    @StateObject private var onboarding: OnboardingViewModel

    init(health: HealthDataProviding = HealthKitService(), defaults: UserDefaults = .standard) {
        _onboarding = StateObject(
            wrappedValue: OnboardingViewModel(health: health, defaults: defaults)
        )
    }

    var body: some View {
        if onboarding.onboardingComplete {
            ContentView()
        } else {
            OnboardingFlow(viewModel: onboarding)
        }
    }
}

#Preview {
    RootView(health: HealthKitService())
}
