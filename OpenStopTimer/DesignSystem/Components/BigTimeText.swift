import SwiftUI

/// The large monospaced-digit time display shared by all four modes. Rather
/// than a fixed point size, this fills whatever box its parent gives it —
/// `fontScale` (0...1) is how much of that box's *height* the digits should
/// claim, so "how tall" is a direct, container-relative setting instead of
/// an arbitrary point-size multiplier. Deliberately huge and heavy — this
/// needs to be readable from across a room, propped on a shelf during a
/// workout, not just up close.
struct BigTimeText: View {
    let interval: TimeInterval
    var fontScale: Double = 1.0
    var showsTenths: Bool = false

    private var formatted: String {
        showsTenths ? TimeFormatting.clockWithTenths(interval) : TimeFormatting.clock(interval)
    }

    var body: some View {
        GeometryReader { proxy in
            Text(formatted)
                // `.monospaced` gives tall, blocky digit glyphs (closer to a
                // digital watch) which read better at a distance than
                // rounded digits do, even at the same point size. A
                // condensed width keeps the glyphs feeling "tall" rather
                // than just wide. The literal point size here is just an
                // upper bound — `minimumScaleFactor` is what actually fits
                // the text to the frame below, both by width and height.
                .font(.system(size: proxy.size.height * 2, weight: .heavy, design: .monospaced).width(.condensed))
                .monospacedDigit()
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .allowsTightening(true)
                .frame(width: proxy.size.width, height: proxy.size.height * fontScale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
        // VoiceOver hears the spoken-friendly label; UI tests read the raw
        // digits back via `.value`, since the label intentionally isn't the
        // literal on-screen string.
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
