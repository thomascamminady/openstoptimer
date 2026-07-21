import SwiftUI

/// A left-to-right row of small "up next" squares — a few steps of lookahead
/// at a glance, rather than a single "what's next" panel. A chip for a work
/// step also shows its round (e.g. "2/10") so you can see, mid-rest, which
/// round is coming up next. When there's a 4th step queued beyond the three
/// full tiles, it's shown sliced in half to hint "more to come" without
/// eating space a full 4th tile would need.
struct UpcomingStepsStrip: View {
    struct Item: Identifiable {
        let id: UUID
        let name: String
        let color: Color
        let duration: TimeInterval
        let roundText: String?
    }

    let items: [Item]

    private let spacing: CGFloat = 8

    var body: some View {
        GeometryReader { proxy in
            let visibleItems = Array(items.prefix(4))
            let hasPeek = visibleItems.count == 4
            let gaps = CGFloat(max(visibleItems.count - 1, 0))
            let units: CGFloat = hasPeek ? 3.5 : CGFloat(visibleItems.count)
            let tileWidth = units > 0 ? (proxy.size.width - spacing * gaps) / units : 0

            HStack(spacing: spacing) {
                ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                    if hasPeek, index == visibleItems.count - 1 {
                        tile(item)
                            .frame(width: tileWidth, alignment: .leading)
                            .frame(width: tileWidth / 2, alignment: .leading)
                            .clipped()
                    } else {
                        tile(item)
                            .frame(width: tileWidth)
                    }
                }
            }
        }
        // Deliberately no fixed height here — the caller sizes this via
        // `.frame(height:)` based on the user's current/next balance setting.
        .accessibilityIdentifier("upcomingStrip")
    }

    private func tile(_ item: Item) -> some View {
        VStack(spacing: 4) {
            Text(item.name.uppercased())
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text("\(Int(item.duration))s")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .opacity(0.85)
            if let roundText = item.roundText {
                Text(roundText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .opacity(0.85)
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(item.color, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("upcomingStrip.item.\(item.id)")
    }
}

#Preview {
    UpcomingStepsStrip(items: [
        .init(id: UUID(), name: "Rest", color: .blue, duration: 15, roundText: nil),
        .init(id: UUID(), name: "Work", color: .red, duration: 30, roundText: "2/10"),
        .init(id: UUID(), name: "Rest", color: .blue, duration: 15, roundText: nil),
        .init(id: UUID(), name: "Work", color: .red, duration: 30, roundText: "3/10"),
    ])
    .frame(height: 92)
    .padding()
}
