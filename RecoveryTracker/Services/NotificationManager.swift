import Foundation

/// Computes the desired set of local notifications from the Settings toggles and
/// reconciles them against what is already pending: adds the ones that should be
/// on (and aren't pending yet) and removes the ones that should be off. Stable
/// identifiers keep re-syncing idempotent — no duplicates.
final class NotificationManager {

    /// Stable identifiers, one per toggle.
    enum Identifier {
        static let dailyReadiness   = "dailyReadiness"
        static let bedtime          = "bedtime"
        static let recoveryInsights = "recoveryInsights"

        static let all = [dailyReadiness, bedtime, recoveryInsights]
    }

    private let scheduler: NotificationScheduling

    init(scheduler: NotificationScheduling) {
        self.scheduler = scheduler
    }

    /// Asks the system for notification authorization. Returns whether granted.
    @discardableResult
    func requestAuthorization() async -> Bool {
        await scheduler.requestAuthorization()
    }

    /// Reconciles scheduled notifications with the current Settings toggles.
    func sync(dailyReadinessOn: Bool, bedtimeReminderOn: Bool, recoveryInsightsOn: Bool) async {
        let desired = Self.desiredSpecs(
            dailyReadinessOn: dailyReadinessOn,
            bedtimeReminderOn: bedtimeReminderOn,
            recoveryInsightsOn: recoveryInsightsOn
        )
        let desiredIDs = Set(desired.map(\.identifier))

        // Remove any of OUR identifiers that should no longer be scheduled.
        let toRemove = Identifier.all.filter { !desiredIDs.contains($0) }
        if !toRemove.isEmpty {
            scheduler.removePending(identifiers: toRemove)
        }

        // Add the missing desired specs; skip ones already pending so re-syncing
        // doesn't create duplicates.
        let pending = Set(await scheduler.pendingIdentifiers())
        for spec in desired where !pending.contains(spec.identifier) {
            await scheduler.add(spec)
        }
    }

    /// Pure mapping from toggles to the notifications that should exist.
    static func desiredSpecs(
        dailyReadinessOn: Bool,
        bedtimeReminderOn: Bool,
        recoveryInsightsOn: Bool
    ) -> [NotificationRequestSpec] {
        var specs: [NotificationRequestSpec] = []

        if dailyReadinessOn {
            specs.append(
                NotificationRequestSpec(
                    identifier: Identifier.dailyReadiness,
                    title: "Daily readiness",
                    body: "Your recovery readiness is ready — check today's score.",
                    hour: 7,
                    minute: 0,
                    repeats: true
                )
            )
        }

        if bedtimeReminderOn {
            specs.append(
                NotificationRequestSpec(
                    identifier: Identifier.bedtime,
                    title: "Bedtime",
                    body: "Time to wind down for better recovery.",
                    hour: 22,
                    minute: 15,
                    repeats: true
                )
            )
        }

        if recoveryInsightsOn {
            specs.append(
                NotificationRequestSpec(
                    identifier: Identifier.recoveryInsights,
                    title: "Recovery insights",
                    body: "New recovery insights are available — see what changed this week.",
                    hour: 18,
                    minute: 0,
                    repeats: true
                )
            )
        }

        return specs
    }
}
