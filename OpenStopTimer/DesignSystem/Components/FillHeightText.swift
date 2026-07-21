import SwiftUI

/// Renders `text` as big, tall, monospaced digits that fill whatever box the
/// parent gives it, rather than a fixed point size — `fillFraction` (0...1)
/// is how much of that box's *height* the digits should claim. Shared by
/// `BigTimeText` (mm:ss) and the metronome's plain seconds-into-cycle number.
struct FillHeightText: View {
    let text: String
    var fillFraction: Double = 1.0

    var body: some View {
        GeometryReader { proxy in
            Text(text)
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
                .frame(width: proxy.size.width, height: proxy.size.height * fillFraction)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        FillHeightText(text: "12:34")
            .frame(height: 200)
        FillHeightText(text: "07", fillFraction: 0.85)
            .frame(height: 200)
    }
}
