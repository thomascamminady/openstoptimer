import SwiftUI
import OpenStopTimerKit

struct LapStopwatchView: View {
    @Environment(AppState.self) private var appState
    @State private var model = LapStopwatchModel()

    var body: some View {
        AdaptiveTimerLayout {
            display
        } controls: {
            HStack(spacing: 28) {
                lapOrResetButton
                PlayerControls(hasStarted: model.hasStarted, isPaused: model.isPaused, showsReset: false, onPrimary: primaryAction)
            }
        }
        .navigationTitle("Lap Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
        .keepScreenAwake(while: model.isRunning)
        .onAppear { model.appearance = appState.globalAppearance }
        .onChange(of: appState.globalAppearance) { _, newValue in model.appearance = newValue }
    }

    private var display: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(.systemBackground)
                BigTimeText(interval: model.displayedElapsed, showsTenths: true)
                    .accessibilityIdentifier("lapStopwatch.display")
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)

            List {
                ForEach(model.laps.reversed()) { lap in
                    HStack {
                        Text("Lap \(lap.index)")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(TimeFormatting.clockWithTenths(lap.lapTime))
                            .monospacedDigit()
                            .foregroundStyle(lapColor(for: lap))
                        Text(TimeFormatting.clockWithTenths(lap.cumulativeTime))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                    }
                    .accessibilityIdentifier("lapStopwatch.lapRow.\(lap.index)")
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("lapStopwatch.lapList")
        }
    }

    private func lapColor(for lap: LapRecord) -> Color {
        if lap.id == model.fastestLapID { return .green }
        if lap.id == model.slowestLapID { return .red }
        return .primary
    }

    @ViewBuilder
    private var lapOrResetButton: some View {
        if model.hasStarted, !model.isRunning {
            Button(action: model.reset) {
                secondaryLabel(systemImage: "arrow.counterclockwise")
            }
            .accessibilityIdentifier("lapStopwatch.reset")
        } else {
            Button(action: model.recordLap) {
                secondaryLabel(systemImage: "flag.fill")
            }
            .disabled(!model.isRunning)
            .opacity(model.isRunning ? 1 : 0.3)
            .accessibilityIdentifier("lapStopwatch.lap")
        }
    }

    private func secondaryLabel(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
            .frame(width: 52, height: 52)
            .background(Circle().fill(.thinMaterial))
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
    NavigationStack { LapStopwatchView() }
        .environment(AppState())
}
