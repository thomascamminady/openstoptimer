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
                BigTimeText(interval: remaining, fontScale: fontScale)
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("currentStep.remaining")
                if let progressText {
                    Text(progressText)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2), in: Capsule())
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
