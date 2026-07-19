import SwiftUI

/// Shared portrait/landscape container for all four modes: a big display
/// area plus a controls area, stacked vertically in portrait (controls at
/// the bottom, thumb-reachable) and placed side-by-side in landscape /
/// compact-height (e.g. a phone propped up during a workout).
struct AdaptiveTimerLayout<Display: View, Controls: View>: View {
    var display: () -> Display
    var controls: () -> Controls

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(@ViewBuilder display: @escaping () -> Display, @ViewBuilder controls: @escaping () -> Controls) {
        self.display = display
        self.controls = controls
    }

    var body: some View {
        if verticalSizeClass == .compact {
            HStack(spacing: 0) {
                display()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                controls()
                    .frame(width: 160)
                    .padding()
            }
        } else {
            VStack(spacing: 0) {
                display()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                controls()
                    .padding(.vertical, 24)
            }
        }
    }
}
