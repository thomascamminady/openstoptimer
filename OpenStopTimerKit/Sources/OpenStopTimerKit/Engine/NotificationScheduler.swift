import Foundation
import UserNotifications

/// Schedules and cancels local notifications for phase transitions so a
/// backgrounded/suspended session still alerts the user at the right wall-clock
/// moments. The in-app UI never depends on these firing — they exist purely for
/// when SwiftUI/the process isn't actively driving the screen.
public struct NotificationScheduler {
    public static let identifierPrefix = "dev.camminady.openstoptimer.transition."

    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorizationIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound])
    }

    /// Cancels any previously scheduled transition notifications. Fire-and-forget
    /// — fine for "the app returned to foreground, stop alerting" where exact
    /// timing doesn't matter. The scheduling methods below use `cancelAllAwaiting`
    /// instead, since racing an in-flight removal against a fresh `add` of the
    /// same identifiers could wipe out the notifications we just scheduled.
    public func cancelAll() {
        center.getPendingNotificationRequests { requests in
            let ids = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(Self.identifierPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    private func cancelAllAwaiting() async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Schedules one notification per remaining phase transition of a running
    /// `PhaseSequenceEngine`, using a bundled sound where available.
    public func scheduleHIITTransitions(engine: PhaseSequenceEngine, appearance: AppearanceConfig) async {
        await cancelAllAwaiting()
        guard appearance.soundsEnabled else { return }
        let now = Date()
        for transition in engine.remainingTransitions() {
            let content = UNMutableNotificationContent()
            if transition.stepIndex < engine.steps.count {
                let step = engine.steps[transition.stepIndex]
                content.title = step.name
                content.body = "\(step.kind.displayName) · \(Int(step.duration))s"
            } else {
                content.title = "Workout Complete"
                content.body = "Nice work!"
            }
            content.sound = Self.notificationSound(for: appearance.sound(for: .phaseStart))

            let interval = max(0.1, transition.date.timeIntervalSince(now))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(Self.identifierPrefix)\(transition.stepIndex)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    /// Schedules a single completion notification for a simple countdown timer.
    public func scheduleSimpleTimerCompletion(finishDate: Date, appearance: AppearanceConfig) async {
        await cancelAllAwaiting()
        guard appearance.soundsEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = "Time's Up"
        content.body = "Your timer has finished."
        content.sound = Self.notificationSound(for: appearance.sound(for: .workoutComplete))

        let interval = max(0.1, finishDate.timeIntervalSince(Date()))
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(Self.identifierPrefix)simple",
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    private static func notificationSound(for choice: SoundChoice) -> UNNotificationSound? {
        guard let resourceName = choice.resourceName else { return nil }
        return UNNotificationSound(named: UNNotificationSoundName("\(resourceName).wav"))
    }
}
