import SwiftUI

/// Shows the current step (big, colored, counting down) alongside a smaller
/// preview of what's next. `ratio` (0...1) controls how much of the
/// available space the current step occupies vs. the next-step preview —
/// one of the "everything is configurable" appearance knobs.
struct CurrentNextPanel: View {
    let currentName: String
    let currentColor: Color
    let currentRemaining: TimeInterval
    let nextName: String?
    let nextColor: Color?
    /// e.g. "ROUND 3/10" or "SET 2/3 · ROUND 4/10" — nil when the current
    /// step isn't part of a round group (warmup/cooldown/single steps).
    var progressText: String?
    var ratio: Double = 0.75
    var fontScale: Double = 1.0

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            Group {
                if isWide {
                    HStack(spacing: 0) {
                        currentSection.frame(width: proxy.size.width * ratio)
                        nextSection.frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 0) {
                        currentSection.frame(height: proxy.size.height * ratio)
                        nextSection.frame(maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private var currentSection: some View {
        ZStack {
            currentColor
            VStack(spacing: 12) {
                Text(currentName.uppercased())
                    .font(.system(size: 22 * fontScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .accessibilityIdentifier("currentNextPanel.currentName")
                BigTimeText(interval: currentRemaining, fontScale: fontScale)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("currentNextPanel.currentRemaining")
                if let progressText {
                    Text(progressText)
                        .font(.system(size: 16 * fontScale, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2), in: Capsule())
                        .accessibilityIdentifier("currentNextPanel.progressText")
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private var nextSection: some View {
        ZStack {
            (nextColor ?? Color.black.opacity(0.85))
            VStack(spacing: 6) {
                Text("NEXT")
                    .font(.system(size: 14 * fontScale, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text(nextName ?? "Finish")
                    .font(.system(size: 24 * fontScale, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("currentNextPanel.nextName")
            }
            .padding()
        }
    }
}

#Preview {
    CurrentNextPanel(
        currentName: "Work",
        currentColor: .red,
        currentRemaining: 18,
        nextName: "Rest",
        nextColor: .blue
    )
}
