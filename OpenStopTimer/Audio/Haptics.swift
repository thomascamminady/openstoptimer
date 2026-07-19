import UIKit

/// Fire-and-forget haptic feedback, deferred the same way `SoundPlayer` is —
/// never block the caller's state-update code on feedback-generator work.
@MainActor
enum Haptics {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        Task {
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    static func success() {
        Task {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
