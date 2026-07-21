import SwiftUI

/// A ring split into 3 fixed thirds (12-4, 4-8, 8-12 o'clock), filling up
/// cumulatively as the second progresses — one lit segment, then two, then
/// all three — rather than only ever lighting the single current one.
/// Monochrome (one `tint`, varying opacity) rather than a traffic-light
/// green/yellow/red, matching the rest of the metronome's plain, colorless
/// aesthetic. Deliberately coarse (updates 3x/second, not continuously)
/// since a runner glancing down needs "roughly how far into this second,"
/// not a precise sweep.
struct SubSecondProgressRing: View {
    /// 0..<1, where the current second started.
    var progress: Double
    var lineWidth: CGFloat = 14
    var tint: Color = .primary

    private static let segmentCount = 3
    /// Small angular gap between segments, as a fraction of the full circle.
    private static let gap = 0.012

    private var activeSegment: Int {
        min(Self.segmentCount - 1, max(0, Int(progress * Double(Self.segmentCount))))
    }

    var body: some View {
        ZStack {
            ForEach(0..<Self.segmentCount, id: \.self) { index in
                segment(index)
            }
        }
    }

    private func segment(_ index: Int) -> some View {
        let start = Double(index) / Double(Self.segmentCount) + Self.gap
        let end = Double(index + 1) / Double(Self.segmentCount) - Self.gap
        return Circle()
            .trim(from: start, to: end)
            .stroke(
                tint.opacity(index <= activeSegment ? 0.9 : 0.15),
                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
    }
}

#Preview {
    VStack(spacing: 40) {
        SubSecondProgressRing(progress: 0.1)
        SubSecondProgressRing(progress: 0.5)
        SubSecondProgressRing(progress: 0.9)
    }
    .padding(40)
}
