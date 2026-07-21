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
                // Explicit layout priorities, not just relative frame
                // flexibility: `controls()` is resolved to its natural
                // intrinsic width *first* (whatever that needs — a single
                // play button vs. HIIT's full skip/pause/skip + Back/Replay
                // rows are very different widths, and some of those
                // internally use `Spacer()`/`.infinity` too), then `display()`
                // unconditionally absorbs everything left over. Without this,
                // two same-priority infinity-flexible siblings would just
                // split the space evenly instead.
                display()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(-1)
                controls()
                    .frame(minWidth: 200)
                    .padding()
                    .layoutPriority(1)
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
