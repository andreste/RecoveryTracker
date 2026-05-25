import Foundation
import UserNotifications

/// A plain value describing one local notification we want scheduled. Keeping
/// this a pure value type lets `NotificationManager`'s scheduling DECISIONS be
/// computed and unit-tested without touching `UNUserNotificationCenter`.
struct NotificationRequestSpec: Equatable {
    let identifier: String
    let title: String
    let body: String
    let hour: Int
    let minute: Int
    let repeats: Bool
}

/// The testable seam over `UNUserNotificationCenter`. The concrete
/// `SystemNotificationScheduler` wraps the real center; tests inject a mock.
protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func add(_ request: NotificationRequestSpec) async
    func removePending(identifiers: [String])
    func pendingIdentifiers() async -> [String]
}

/// Production implementation backed by `UNUserNotificationCenter`. Converts a
/// `NotificationRequestSpec` into a `UNNotificationRequest` driven by a
/// `UNCalendarNotificationTrigger`. Re-adding with the same identifier replaces
/// the existing pending request, so scheduling stays idempotent.
final class SystemNotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func add(_ request: NotificationRequestSpec) async {
        let content = UNMutableNotificationContent()
        content.title = request.title
        content.body = request.body
        content.sound = .default

        var components = DateComponents()
        components.hour = request.hour
        components.minute = request.minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: request.repeats)

        let unRequest = UNNotificationRequest(
            identifier: request.identifier,
            content: content,
            trigger: trigger
        )
        try? await center.add(unRequest)
    }

    func removePending(identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func pendingIdentifiers() async -> [String] {
        await center.pendingNotificationRequests().map(\.identifier)
    }
}
