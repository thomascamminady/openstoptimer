import SwiftUI

/// The dominant, full-width display for whatever step is currently playing.
/// `progressText` (e.g. "ROUND 3/10") is deliberately shown only while a
/// work step is active — during rest it would just be visual noise, since
/// rest isn't itself "round 3," it's the gap between rounds.
struct CurrentStepView: View {
    let name: String
    let color: Color
    let remaining: TimeInterval
    var progressText: String?
    var fontScale: Double = 1.0

    var body: some View {
        ZStack {
            color
            VStack(spacing: 14) {
                Text(name.uppercased())
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("currentStep.name")
                // `fontScale` here is how much of the remaining box height
                // the digits themselves should fill — see BigTimeText.
                BigTimeText(interval: remaining, fontScale: fontScale, isCountdown: true)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("currentStep.remaining")
                if let progressText {
                    Text(progressText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.28), in: Capsule())
                        .overlay(Capsule().strokeBorder(.white.opacity(0.4), lineWidth: 1.5))
                        .fixedSize()
                        .accessibilityIdentifier("currentStep.progressText")
                }
            }
            .padding()
        }
    }
}

#Preview {
    CurrentStepView(name: "Work", color: .red, remaining: 18, progressText: "ROUND 3/10")
}
