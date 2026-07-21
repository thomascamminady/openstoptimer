import SwiftUI

/// A thin circular track plus a thicker arc sweeping clockwise from 12
/// o'clock as `progress` (0..<1) advances — sub-second resolution around
/// the metronome's whole-second number, so a runner can tell whether
/// they're in roughly the first, second, or third part of the current
/// second without needing a decimal readout.
struct SubSecondProgressRing: View {
    /// 0..<1, where the current second started.
    var progress: Double
    var lineWidth: CGFloat = 14
    var tint: Color = .primary

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        SubSecondProgressRing(progress: 0.15)
        SubSecondProgressRing(progress: 0.65)
    }
    .padding(40)
}
