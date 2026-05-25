import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileCard

                    SectionLabel(text: "Goal")
                    SettingsGroup {
                        SelectRow(icon: "target", accent: .rtCoral,
                                  label: "Training goal",
                                  value: "\(viewModel.trainingGoal.displayName) · 16 weeks")
                        SelectRow(icon: "flame.fill", accent: .rtAmber,
                                  label: "Weekly target", value: "55 km · 320 au")
                        SelectRow(icon: "bolt.fill", accent: .rtPurple,
                                  label: "Race day", value: "Oct 12, 2026",
                                  showSeparator: false)
                    }

                    SectionLabel(text: "Notifications")
                    SettingsGroup {
                        ToggleRow(icon: "bell.fill", accent: .rtCoral,
                                  label: "Daily readiness", subtitle: "Morning summary",
                                  isOn: $viewModel.dailyReadinessOn, time: "7:00 AM")
                        ToggleRow(icon: "moon.fill", accent: .rtPurple,
                                  label: "Bedtime reminder", subtitle: "Wind down",
                                  isOn: $viewModel.bedtimeReminderOn, time: "10:15 PM")
                        ToggleRow(icon: "sparkles", accent: .rtTeal,
                                  label: "Recovery insights", subtitle: "Anomaly alerts",
                                  isOn: $viewModel.recoveryInsightsOn,
                                  showSeparator: false)
                    }

                    SectionLabel(text: "Connected sources")
                    SettingsGroup {
                        SourceRow(icon: "applelogo", accent: .red,
                                  label: "Apple Health",
                                  status: "4 data types · synced 2m ago", connected: true)
                        SourceRow(icon: "applewatch", accent: .rtText,
                                  label: "Apple Watch", status: "Series 10 · GPS",
                                  connected: true)
                        SourceRow(icon: "bolt.heart.fill", accent: .rtCoral,
                                  label: "Whoop", status: "Not connected",
                                  connected: false, showSeparator: false)
                    }

                    SectionLabel(text: "About")
                    SettingsGroup {
                        PlainRow(label: "Privacy", value: "On-device")
                        PlainRow(label: "Help & feedback")
                        PlainRow(label: "Version", value: "2.4.1 (build 412)",
                                 showChevron: false, showSeparator: false)
                    }

                    Text("Made with care · Recovery Tracker")
                        .font(.rtFootnote)
                        .foregroundColor(.rtText3)
                        .frame(maxWidth: .infinity)
                        .padding(.top, RTSpacing.lg)
                        .padding(.bottom, RTSpacing.md)
                }
                .padding(.bottom, RTSpacing.lg)
            }
            .background(Color.rtBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var profileCard: some View {
        SettingsGroup {
            HStack(spacing: RTSpacing.md) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.rtTeal, .rtPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                        .frame(width: 56, height: 56)
                    Text("JS")
                        .font(.rtHeadline)
                        .foregroundColor(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Jamie Sato")
                        .font(.rtHeadline)
                        .foregroundColor(.rtText)
                    Text("34 · Running · 142 days tracked")
                        .font(.rtSubhead)
                        .foregroundColor(.rtText3)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.rtText4)
            }
            .padding(.horizontal, RTSpacing.cardPad)
            .padding(.vertical, RTSpacing.md)
        }
        .padding(.top, RTSpacing.md)
    }
}

#Preview {
    SettingsView()
}
