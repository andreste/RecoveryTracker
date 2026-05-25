import SwiftUI

/// Two-step first-run onboarding: pick a sport, then connect Apple Health.
/// Gated by `OnboardingViewModel.onboardingComplete`; `RootView` swaps to the
/// tab bar once the flag flips.
///
/// `OnboardingFlow` renders the steps from a VM owned by `RootView`, so the
/// flag change propagates up and triggers the swap to the tab bar.
struct OnboardingFlow: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        ZStack {
            Color.rtBackground.ignoresSafeArea()

            if viewModel.step == 1 {
                SportSelectionStep(viewModel: viewModel)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                HealthPermissionStep(viewModel: viewModel)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
    }
}

// MARK: - Step indicator

private struct StepIndicator: View {
    let current: Int  // 1 or 2

    var body: some View {
        HStack(spacing: RTSpacing.sm) {
            ForEach(1...2, id: \.self) { step in
                Capsule()
                    .fill(step <= current ? Color.rtTeal : Color.rtText4)
                    .frame(width: step == current ? 24 : 18, height: 6)
            }
        }
    }
}

// MARK: - Step 1: Sport selection

private struct SportSelectionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    private let columns = [
        GridItem(.flexible(), spacing: RTSpacing.md),
        GridItem(.flexible(), spacing: RTSpacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                StepIndicator(current: 1)
                Spacer()
                Button("Skip") { viewModel.skip() }
                    .font(.rtSubhead)
                    .foregroundColor(.rtText3)
            }
            .padding(.top, RTSpacing.sm)

            Text("What's your main sport?")
                .font(.rtLargeTitle)
                .foregroundColor(.rtText)
                .padding(.top, RTSpacing.lg)

            Text("We'll tune training load thresholds and recovery cost for your discipline.")
                .font(.rtSubhead)
                .foregroundColor(.rtText2)
                .padding(.top, RTSpacing.sm)

            LazyVGrid(columns: columns, spacing: RTSpacing.md) {
                ForEach(Discipline.allCases) { discipline in
                    DisciplineTile(
                        discipline: discipline,
                        isSelected: viewModel.selectedDiscipline == discipline
                    ) {
                        viewModel.selectDiscipline(discipline)
                    }
                }
            }
            .padding(.top, RTSpacing.lg)

            Spacer()

            CTAButton(title: "Continue") { viewModel.advance() }
                .disabled(viewModel.selectedDiscipline == nil)
                .opacity(viewModel.selectedDiscipline == nil ? 0.5 : 1)
        }
        .padding(.horizontal, RTSpacing.titlePad)
        .padding(.bottom, RTSpacing.lg)
    }
}

private struct DisciplineTile: View {
    let discipline: Discipline
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: RTSpacing.md) {
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: RTRadius.iconTile, style: .continuous)
                            .fill(isSelected ? discipline.accentColor : discipline.accentColor.opacity(0.12))
                            .frame(width: 52, height: 52)
                        Image(systemName: discipline.symbolName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(isSelected ? .white : discipline.accentColor)
                    }
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(discipline.accentColor)
                    }
                }

                Text(discipline.displayName)
                    .font(.rtHeadline)
                    .foregroundColor(.rtText)

                Text(discipline.subtitle)
                    .font(.rtCaption)
                    .foregroundColor(.rtText2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(RTSpacing.cardPad)
            .background(Color.rtCard)
            .overlay(
                RoundedRectangle(cornerRadius: RTRadius.onboardingTile, style: .continuous)
                    .stroke(isSelected ? discipline.accentColor : Color.clear, lineWidth: 2)
            )
            .cornerRadius(RTRadius.onboardingTile)
            .rtCardShadow()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: HealthKit permission

private struct HealthPermissionStep: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button { viewModel.back() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.rtText2)
                }
                Spacer()
                StepIndicator(current: 2)
                Spacer()
                // Balance the back chevron so the indicator stays centered.
                Image(systemName: "chevron.left").opacity(0)
            }
            .padding(.top, RTSpacing.sm)

            VStack(alignment: .leading, spacing: RTSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: RTRadius.card, style: .continuous)
                        .fill(LinearGradient(
                            colors: [.rtCoral, .rtPurple],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))
                        .frame(width: 64, height: 64)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }

                Text("Connect Apple Health")
                    .font(.rtLargeTitle)
                    .foregroundColor(.rtText)

                Text("We read four data types to compute your daily readiness score.")
                    .font(.rtSubhead)
                    .foregroundColor(.rtText2)
            }
            .padding(.top, RTSpacing.lg)

            VStack(spacing: RTSpacing.md) {
                PermissionRow(icon: "heart.fill", color: .rtCoral,
                              label: "Heart Rate", subtitle: "For HRV & resting HR")
                PermissionRow(icon: "bed.double.fill", color: .rtPurple,
                              label: "Sleep Analysis", subtitle: "Quality & sleep stages")
                PermissionRow(icon: "figure.run", color: .rtAmber,
                              label: "Workouts", subtitle: "Type, duration, intensity")
                PermissionRow(icon: "flame.fill", color: .rtTeal,
                              label: "Active Energy", subtitle: "Training load estimation")
            }
            .padding(.top, RTSpacing.lg)

            HStack(spacing: RTSpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.rtText3)
                Text("Data stays on your device. Nothing is uploaded without explicit opt-in.")
                    .font(.rtFootnote)
                    .foregroundColor(.rtText3)
            }
            .padding(.top, RTSpacing.lg)

            Spacer()

            CTAButton(title: "Connect Apple Health", systemIcon: "applelogo") {
                Task { await viewModel.connectHealth() }
            }

            SecondaryCTAButton(title: "Maybe later") { viewModel.complete() }
        }
        .padding(.horizontal, RTSpacing.titlePad)
        .padding(.bottom, RTSpacing.lg)
    }
}

private struct PermissionRow: View {
    let icon: String
    let color: Color
    let label: String
    let subtitle: String

    var body: some View {
        HStack(spacing: RTSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: RTRadius.iconTile, style: .continuous)
                    .fill(color.opacity(0.14))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.rtBody)
                    .foregroundColor(.rtText)
                Text(subtitle)
                    .font(.rtCaption)
                    .foregroundColor(.rtText2)
            }
            Spacer()
        }
        .padding(RTSpacing.rowPad)
        .background(Color.rtCard)
        .cornerRadius(RTRadius.card)
        .rtCardShadow()
    }
}

#Preview {
    OnboardingFlow(viewModel: OnboardingViewModel(health: HealthKitService()))
}
