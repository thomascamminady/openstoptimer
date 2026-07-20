import SwiftUI

/// A left-to-right row of small "up next" squares — a few steps of lookahead
/// at a glance, rather than a single "what's next" panel. A chip for a work
/// step also shows its round (e.g. "R2/10") so you can see, mid-rest, which
/// round is coming up next.
struct UpcomingStepsStrip: View {
    struct Item: Identifiable {
        let id: UUID
        let name: String
        let color: Color
        let duration: TimeInterval
        let roundText: String?
    }

    let items: [Item]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(items) { item in
                VStack(spacing: 2) {
                    Text(item.name.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("\(Int(item.duration))s")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .opacity(0.85)
                    if let roundText = item.roundText {
                        Text(roundText)
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .opacity(0.85)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background(item.color, in: RoundedRectangle(cornerRadius: 12))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("upcomingStrip.item.\(item.id)")
            }
        }
        .frame(height: 60)
        .accessibilityIdentifier("upcomingStrip")
    }
}

#Preview {
    UpcomingStepsStrip(items: [
        .init(id: UUID(), name: "Rest", color: .blue, duration: 15, roundText: nil),
        .init(id: UUID(), name: "Work", color: .red, duration: 30, roundText: "R2/10"),
        .init(id: UUID(), name: "Rest", color: .blue, duration: 15, roundText: nil),
    ])
    .padding()
}
