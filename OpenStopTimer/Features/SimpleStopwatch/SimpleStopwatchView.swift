import SwiftUI

struct SimpleStopwatchView: View {
    @State private var model = SimpleStopwatchModel()

    var body: some View {
        AdaptiveTimerLayout {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                BigTimeText(interval: model.displayedElapsed, showsTenths: true)
                    .accessibilityIdentifier("simpleStopwatch.display")
            }
        } controls: {
            PlayerControls(
                hasStarted: model.hasStarted,
                isPaused: model.isPaused,
                showsReset: false,
                onPrimary: primaryAction
            )
        }
        .navigationTitle("Simple Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
        .keepScreenAwake(while: model.isRunning)
    }

    private func primaryAction() {
        if !model.hasStarted {
            model.start()
        } else {
            model.togglePause()
        }
    }
}

#Preview {
    NavigationStack { SimpleStopwatchView() }
}
