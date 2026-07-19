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
        HStack(spacing: 28) {
            if showsReset, hasStarted {
                secondaryButton(systemImage: "arrow.counterclockwise", action: onReset)
                    .accessibilityIdentifier("playerControls.reset")
            }
            if showsSkip {
                secondaryButton(systemImage: "backward.end.fill", action: onSkipBack)
                    .accessibilityIdentifier("playerControls.skipBack")
            }
            primaryButton
            if showsSkip {
                secondaryButton(systemImage: "forward.end.fill", action: onSkipForward)
                    .accessibilityIdentifier("playerControls.skipForward")
            }
        }
    }

    private var primaryButton: some View {
        Button(action: onPrimary) {
            Image(systemName: primaryIcon)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(Circle().fill(primaryColor))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(primaryAccessibilityLabel)
        .accessibilityIdentifier("playerControls.primary")
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
        Button {
            action?()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
                .background(Circle().fill(.thinMaterial))
        }
        .buttonStyle(.plain)
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
