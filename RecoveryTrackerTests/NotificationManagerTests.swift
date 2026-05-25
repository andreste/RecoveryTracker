import Testing
import Foundation
@testable import RecoveryTracker

/// Records add/remove calls and returns canned pending identifiers so the
/// scheduling DECISIONS in `NotificationManager` can be tested without
/// touching `UNUserNotificationCenter`.
private actor MockNotificationScheduler: NotificationScheduling {
    private(set) var added: [NotificationRequestSpec] = []
    private(set) var removed: [String] = []
    var pending: [String]

    init(pending: [String] = []) {
        self.pending = pending
    }

    func requestAuthorization() async -> Bool { true }

    func add(_ request: NotificationRequestSpec) async {
        added.append(request)
        if !pending.contains(request.identifier) {
            pending.append(request.identifier)
        }
    }

    func removePending(identifiers: [String]) {
        removed.append(contentsOf: identifiers)
        pending.removeAll { identifiers.contains($0) }
    }

    func pendingIdentifiers() async -> [String] { pending }
}

struct NotificationManagerTests {

    @Test func allTogglesOnSchedulesThreeSpecs() async {
        let scheduler = MockNotificationScheduler()
        let manager = NotificationManager(scheduler: scheduler)

        await manager.sync(dailyReadinessOn: true, bedtimeReminderOn: true, recoveryInsightsOn: true)

        let added = await scheduler.added
        let byID = Dictionary(uniqueKeysWithValues: added.map { ($0.identifier, $0) })

        #expect(Set(byID.keys) == ["dailyReadiness", "bedtime", "recoveryInsights"])

        let readiness = byID["dailyReadiness"]
        #expect(readiness?.hour == 7)
        #expect(readiness?.minute == 0)
        #expect(readiness?.repeats == true)

        let bedtime = byID["bedtime"]
        #expect(bedtime?.hour == 22)
        #expect(bedtime?.minute == 15)
        #expect(bedtime?.repeats == true)

        #expect(byID["recoveryInsights"]?.repeats == true)
    }

    @Test func toggleOffRemovesAndDoesNotAdd() async {
        let scheduler = MockNotificationScheduler()
        let manager = NotificationManager(scheduler: scheduler)

        await manager.sync(dailyReadinessOn: true, bedtimeReminderOn: false, recoveryInsightsOn: false)

        let added = await scheduler.added
        let removed = await scheduler.removed
        let addedIDs = Set(added.map(\.identifier))

        #expect(addedIDs == ["dailyReadiness"])
        #expect(addedIDs.contains("bedtime") == false)
        #expect(removed.contains("bedtime"))
        #expect(removed.contains("recoveryInsights"))
    }

    @Test func reSyncWithSameSettingsDoesNotDuplicate() async {
        let scheduler = MockNotificationScheduler()
        let manager = NotificationManager(scheduler: scheduler)

        await manager.sync(dailyReadinessOn: true, bedtimeReminderOn: true, recoveryInsightsOn: false)
        await manager.sync(dailyReadinessOn: true, bedtimeReminderOn: true, recoveryInsightsOn: false)

        let added = await scheduler.added
        let readinessAdds = added.filter { $0.identifier == "dailyReadiness" }
        let bedtimeAdds = added.filter { $0.identifier == "bedtime" }

        #expect(readinessAdds.count == 1)
        #expect(bedtimeAdds.count == 1)
    }

    @Test func turningPreviouslyOnToggleOffRemovesExactlyThatIdentifier() async {
        let scheduler = MockNotificationScheduler()
        let manager = NotificationManager(scheduler: scheduler)

        await manager.sync(dailyReadinessOn: true, bedtimeReminderOn: true, recoveryInsightsOn: false)
        await manager.sync(dailyReadinessOn: true, bedtimeReminderOn: false, recoveryInsightsOn: false)

        let removed = await scheduler.removed
        #expect(removed.contains("bedtime"))
        #expect(removed.contains("dailyReadiness") == false)
    }
}
