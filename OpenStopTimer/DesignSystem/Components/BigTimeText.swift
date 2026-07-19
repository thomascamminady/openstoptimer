import SwiftUI

/// The large monospaced-digit time display shared by all four modes. Scales
/// relative to Dynamic Type via `@ScaledMetric`, then multiplied by the
/// user's `fontScale` appearance setting.
struct BigTimeText: View {
    let interval: TimeInterval
    var fontScale: Double = 1.0
    var showsTenths: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var baseSize: CGFloat = 84

    private var formatted: String {
        showsTenths ? TimeFormatting.clockWithTenths(interval) : TimeFormatting.clock(interval)
    }

    var body: some View {
        Text(formatted)
            .font(.system(size: baseSize * fontScale, weight: .bold, design: .rounded))
            .monospacedDigit()
            .minimumScaleFactor(0.3)
            .lineLimit(1)
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
