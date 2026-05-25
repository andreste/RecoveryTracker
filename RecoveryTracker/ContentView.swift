import SwiftUI

struct ContentView: View {
    @State private var selectedTab: RootTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                tabView(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .tint(.rtTeal)
    }

    @ViewBuilder
    private func tabView(for tab: RootTab) -> some View {
        switch tab {
        case .today:    TodayView()
        case .trends:   TrendsView()
        case .training: TrainingView()
        case .settings: SettingsView()
        }
    }
}

#Preview {
    ContentView()
}
