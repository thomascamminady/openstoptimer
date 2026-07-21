import SwiftUI

/// A circular icon button in one of two visual weights, shared by every
/// player-style control row (Simple Timer/Stopwatch, Lap Stopwatch, HIIT,
/// Metronome) so tap targets stay big, obvious, and visually consistent
/// across the whole app rather than each screen sizing its own buttons.
struct CircularIconButton: View {
    enum Style {
        /// The main action — big, filled with a solid color, white icon.
        case primary(color: Color)
        /// A supporting action — smaller, translucent material, tinted icon.
        case secondary
    }

    let systemImage: String
    var style: Style = .secondary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: diameter, height: diameter)
                .background(background)
        }
        .buttonStyle(.plain)
    }

    private var diameter: CGFloat {
        switch style {
        case .primary: 96
        case .secondary: 64
        }
    }

    private var iconSize: CGFloat {
        switch style {
        case .primary: 34
        case .secondary: 24
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: .white
        case .secondary: .primary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary(let color):
            Circle().fill(color)
        case .secondary:
            Circle().fill(.thinMaterial)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CircularIconButton(systemImage: "play.fill", style: .primary(color: .green)) {}
        CircularIconButton(systemImage: "arrow.counterclockwise", style: .secondary) {}
    }
}
