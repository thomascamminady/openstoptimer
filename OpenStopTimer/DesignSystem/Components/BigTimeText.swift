import SwiftUI

/// The large monospaced-digit time display shared by all four modes. Scales
/// relative to Dynamic Type via `@ScaledMetric`, then multiplied by the
/// user's `fontScale` appearance setting. Deliberately huge and heavy —
/// this needs to be readable from across a room, propped on a shelf during
/// a workout, not just up close.
struct BigTimeText: View {
    let interval: TimeInterval
    var fontScale: Double = 1.0
    var showsTenths: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var baseSize: CGFloat = 260

    private var formatted: String {
        showsTenths ? TimeFormatting.clockWithTenths(interval) : TimeFormatting.clock(interval)
    }

    var body: some View {
        Text(formatted)
            // `.monospaced` gives tall, blocky digit glyphs (closer to a
            // digital watch) which read better at a distance than rounded
            // digits do, even at the same point size.
            .font(.system(size: baseSize * fontScale, weight: .black, design: .monospaced))
            .monospacedDigit()
            .minimumScaleFactor(0.1)
            .lineLimit(1)
            .allowsTightening(true)
            // VoiceOver hears the spoken-friendly label; UI tests read the
            // raw digits back via `.value`, since the label intentionally
            // isn't the literal on-screen string.
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(formatted)
    }

    private var accessibilityLabel: String {
        let total = Int(interval.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return "\(minutes) minutes \(seconds) seconds"
    }
}

#Preview {
    VStack(spacing: 24) {
        BigTimeText(interval: 75, showsTenths: false)
        BigTimeText(interval: 75.4, showsTenths: true)
        BigTimeText(interval: 3725, fontScale: 0.6)
    }
}
