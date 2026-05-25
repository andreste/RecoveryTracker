import SwiftUI

// MARK: - Settings group container

struct SettingsGroup<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color.rtCard)
        .cornerRadius(RTRadius.card)
        .padding(.horizontal, RTSpacing.screen)
    }
}

// MARK: - Filled icon tile (solid accent background, white icon)

struct SettingsIconTile: View {
    let icon: String
    let accent: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: RTRadius.badge)
                .fill(accent)
                .frame(width: 30, height: 30)
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Select row (label, value, chevron)

struct SelectRow: View {
    let icon: String
    let accent: Color
    let label: String
    let value: String
    var showSeparator: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconTile(icon: icon, accent: accent)
            Text(label)
                .font(.rtBody)
                .foregroundColor(.rtText)
                .kerning(-0.2)
            Spacer()
            Text(value)
                .font(.rtSubhead)
                .foregroundColor(.rtText3)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.rtText4)
        }
        .padding(.horizontal, RTSpacing.rowPad)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Color.rtSeparator.frame(height: 0.5).padding(.leading, 56)
            }
        }
    }
}

// MARK: - Toggle row (switch, optional time display)

struct ToggleRow: View {
    let icon: String
    let accent: Color
    let label: String
    let subtitle: String
    @Binding var isOn: Bool
    var time: String? = nil
    var showSeparator: Bool = true

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconTile(icon: icon, accent: accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.rtBody)
                    .foregroundColor(.rtText)
                    .kerning(-0.2)
                Text(isOn ? (time.map { "\(subtitle) · \($0)" } ?? subtitle) : subtitle)
                    .font(.rtCaption)
                    .foregroundColor(.rtText3)
            }
            Spacer()
            RTToggle(isOn: $isOn)
        }
        .padding(.horizontal, RTSpacing.rowPad)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Color.rtSeparator.frame(height: 0.5).padding(.leading, 56)
            }
        }
    }
}

// MARK: - Source row (connected integration)

struct SourceRow: View {
    let icon: String
    let accent: Color
    let label: String
    let status: String
    var connected: Bool = true
    var showSeparator: Bool = true
    var onConnect: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(accent)
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.rtBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.rtText)
                    .kerning(-0.2)
                HStack(spacing: 4) {
                    if connected {
                        Circle().fill(Color.rtTeal).frame(width: 5, height: 5)
                    }
                    Text(status)
                        .font(.rtCaption)
                        .foregroundColor(connected ? .rtTeal : .rtText3)
                }
            }
            Spacer()
            if connected {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.rtText4)
            } else {
                Button("Connect", action: onConnect)
                    .font(.rtFootnote)
                    .fontWeight(.semibold)
                    .foregroundColor(.rtTeal)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Color.rtTealSoft)
                    .cornerRadius(RTRadius.pill)
            }
        }
        .padding(.horizontal, RTSpacing.rowPad)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Color.rtSeparator.frame(height: 0.5).padding(.leading, 60)
            }
        }
    }
}

// MARK: - Plain row (label, optional value, optional chevron)

struct PlainRow: View {
    let label: String
    var value: String? = nil
    var showChevron: Bool = true
    var showSeparator: Bool = true

    var body: some View {
        HStack(spacing: RTSpacing.sm) {
            Text(label)
                .font(.rtBody)
                .foregroundColor(.rtText)
                .kerning(-0.2)
            Spacer()
            if let value {
                Text(value)
                    .font(.rtSubhead)
                    .foregroundColor(.rtText3)
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.rtText4)
            }
        }
        .padding(.horizontal, RTSpacing.cardPad)
        .padding(.vertical, 13)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) {
            if showSeparator {
                Color.rtSeparator.frame(height: 0.5).padding(.leading, 16)
            }
        }
    }
}

// MARK: - Custom iOS-style toggle

struct RTToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack(alignment: isOn ? .trailing : .leading) {
            Capsule()
                .fill(isOn ? Color.rtTeal : Color(UIColor.systemGray4))
                .frame(width: 51, height: 31)
                .animation(.easeInOut(duration: 0.15), value: isOn)
            Circle()
                .fill(Color.white)
                .frame(width: 27, height: 27)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 3)
                .shadow(color: .black.opacity(0.06), radius: 1, x: 0, y: 1)
                .padding(2)
                .animation(.easeInOut(duration: 0.15), value: isOn)
        }
        .onTapGesture { isOn.toggle() }
    }
}

#Preview {
    struct Preview: View {
        @State var t1 = true
        @State var t2 = false
        @State var t3 = true

        var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    SectionLabel(text: "Goal")
                    SettingsGroup {
                        SelectRow(icon: "target",       accent: .rtCoral,   label: "Training goal",    value: "Marathon · 16 weeks")
                        SelectRow(icon: "bolt.fill",    accent: .rtAmber,   label: "Weekly target",    value: "55 km", showSeparator: false)
                    }
                    SectionLabel(text: "Notifications")
                    SettingsGroup {
                        ToggleRow(icon: "bell.fill",    accent: .rtCoral,   label: "Daily readiness",  subtitle: "Morning summary", isOn: $t1, time: "7:00 AM")
                        ToggleRow(icon: "sparkles",     accent: .rtTeal,    label: "Recovery insights",subtitle: "Anomaly alerts",   isOn: $t2, showSeparator: false)
                    }
                    SectionLabel(text: "Sources")
                    SettingsGroup {
                        SourceRow(icon: "applelogo",    accent: .red,        label: "Apple Health",     status: "4 types · synced 2m ago", connected: true)
                        SourceRow(icon: "heart.fill",   accent: .rtCoral,    label: "Whoop",            status: "Not connected", connected: false, showSeparator: false)
                    }
                    SectionLabel(text: "About")
                    SettingsGroup {
                        PlainRow(label: "Privacy", value: "On-device")
                        PlainRow(label: "Version", value: "2.4.1", showChevron: false, showSeparator: false)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.rtBackground)
        }
    }
    return Preview()
}
