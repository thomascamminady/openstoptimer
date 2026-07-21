import SwiftUI

/// The large tabular-digit time display shared by all four modes.
/// `fontScale` (0...1) is how much of the available height the digits
/// should claim — see `FillHeightText`. Deliberately huge — this needs to
/// be readable from across a room, propped on a shelf during a workout,
/// not just up close.
struct BigTimeText: View {
    let interval: TimeInterval
    var fontScale: Double = 1.0
    var showsTenths: Bool = false

    private var formatted: String {
        showsTenths ? TimeFormatting.clockWithTenths(interval) : TimeFormatting.clock(interval)
    }

    var body: some View {
        FillHeightText(text: formatted, fillFraction: fontScale)
            // VoiceOver hears the spoken-friendly label; UI tests read the
            // raw digits back via `.value`, since the label intentionally
            // isn't the literal on-screen string.
            .accessibilityElement(children: .ignore)
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
            .frame(height: 200)
        BigTimeText(interval: 75.4, showsTenths: true)
            .frame(height: 120)
        BigTimeText(interval: 3725, fontScale: 0.5)
            .frame(height: 200)
    }
}
