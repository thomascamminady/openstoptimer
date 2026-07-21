import SwiftUI

/// Start/pause/resume + optional skip/reset row shared by every player
/// screen (Simple Timer, Simple Stopwatch, Lap Stopwatch, HIIT Player).
struct PlayerControls: View {
    let hasStarted: Bool
    let isPaused: Bool
    var showsSkip: Bool = false
    var showsReset: Bool = true

    let onPrimary: () -> Void
    var onReset: (() -> Void)?
    var onSkipBack: (() -> Void)?
    var onSkipForward: (() -> Void)?

    var body: some View {
        HStack(spacing: 32) {
            if showsReset, hasStarted {
                secondaryButton(systemImage: "arrow.counterclockwise", action: onReset)
                    .accessibilityIdentifier("playerControls.reset")
            }
            if showsSkip {
                secondaryButton(systemImage: "backward.end.fill", action: onSkipBack)
                    .accessibilityIdentifier("playerControls.skipBack")
            }
            CircularIconButton(systemImage: primaryIcon, style: .primary(color: primaryColor), action: onPrimary)
                .accessibilityLabel(primaryAccessibilityLabel)
                .accessibilityIdentifier("playerControls.primary")
            if showsSkip {
                secondaryButton(systemImage: "forward.end.fill", action: onSkipForward)
                    .accessibilityIdentifier("playerControls.skipForward")
            }
        }
    }

    private var primaryIcon: String {
        (!hasStarted || isPaused) ? "play.fill" : "pause.fill"
    }

    private var primaryAccessibilityLabel: String {
        (!hasStarted || isPaused) ? "Start" : "Pause"
    }

    private var primaryColor: Color {
        (!hasStarted || isPaused) ? .green : .orange
    }

    private func secondaryButton(systemImage: String, action: (() -> Void)?) -> some View {
        CircularIconButton(systemImage: systemImage, style: .secondary) {
            action?()
        }
        .disabled(action == nil)
        .opacity(action == nil ? 0.3 : 1)
    }
}

#Preview {
    VStack(spacing: 40) {
        PlayerControls(hasStarted: false, isPaused: false, onPrimary: {})
        PlayerControls(hasStarted: true, isPaused: false, showsSkip: true, onPrimary: {}, onReset: {}, onSkipBack: {}, onSkipForward: {})
    }
}
