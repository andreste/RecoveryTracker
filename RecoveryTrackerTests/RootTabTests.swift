import Testing
@testable import RecoveryTracker

struct RootTabTests {
    @Test func exactlyFourTabs() {
        #expect(RootTab.allCases.count == 4)
    }

    @Test func tabOrderIsCorrect() {
        let cases = RootTab.allCases
        #expect(cases[0] == .today)
        #expect(cases[1] == .trends)
        #expect(cases[2] == .training)
        #expect(cases[3] == .settings)
    }

    @Test func tabTitles() {
        #expect(RootTab.today.title == "Today")
        #expect(RootTab.trends.title == "Trends")
        #expect(RootTab.training.title == "Training")
        #expect(RootTab.settings.title == "Settings")
    }

    @Test func tabSymbolNames() {
        #expect(RootTab.today.systemImage == "house")
        #expect(RootTab.trends.systemImage == "chart.bar")
        #expect(RootTab.training.systemImage == "figure.strengthtraining.traditional")
        #expect(RootTab.settings.systemImage == "gearshape")
    }
}
