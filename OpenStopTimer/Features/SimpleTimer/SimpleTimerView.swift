import SwiftUI

/// The "set it for the kitchen" timer: a duration wheel, a start button,
/// nothing else to think about.
struct SimpleTimerView: View {
    @State private var model = SimpleTimerModel()
    @Environment(\.scenePhase) private var scenePhase

    private var hours: Binding<Int> {
        Binding(
            get: { Int(model.selectedDuration) / 3600 },
            set: { model.selectedDuration = TimeInterval($0 * 3600 + minutes.wrappedValue * 60 + seconds.wrappedValue) }
        )
    }
    private var minutes: Binding<Int> {
        Binding(
            get: { (Int(model.selectedDuration) % 3600) / 60 },
            set: { model.selectedDuration = TimeInterval(hours.wrappedValue * 3600 + $0 * 60 + seconds.wrappedValue) }
        )
    }
    private var seconds: Binding<Int> {
        Binding(
            get: { Int(model.selectedDuration) % 60 },
            set: { model.selectedDuration = TimeInterval(hours.wrappedValue * 3600 + minutes.wrappedValue * 60 + $0) }
        )
    }

    var body: some View {
        AdaptiveTimerLayout {
            display
        } controls: {
            PlayerControls(
                hasStarted: model.hasStarted,
                isPaused: model.isPaused,
                onPrimary: primaryAction,
                onReset: model.reset
            )
        }
        .navigationTitle("Simple Timer")
        .navigationBarTitleDisplayMode(.inline)
        .keepScreenAwake(while: model.isRunning)
        .onChange(of: scenePhase) { _, newValue in
            model.handleScenePhase(isActive: newValue == .active)
        }
    }

    @ViewBuilder
    private var display: some View {
        if model.hasStarted {
            ZStack {
                (model.isFinished ? Color.green : Color(.systemBackground))
                    .ignoresSafeArea()
                BigTimeText(interval: model.displayedRemaining)
                    .foregroundStyle(model.isFinished ? .white : .primary)
                    .accessibilityIdentifier("simpleTimer.display")
            }
        } else {
            durationPicker
        }
    }

    private var durationPicker: some View {
        HStack(spacing: 0) {
            wheel(binding: hours, range: 0..<4, unit: "hr", identifier: "simpleTimer.hoursPicker")
            wheel(binding: minutes, range: 0..<60, unit: "min", identifier: "simpleTimer.minutesPicker")
            wheel(binding: seconds, range: 0..<60, unit: "sec", identifier: "simpleTimer.secondsPicker")
        }
        .padding(.horizontal)
    }

    private func wheel(binding: Binding<Int>, range: Range<Int>, unit: String, identifier: String) -> some View {
        HStack(spacing: 4) {
            Picker(unit, selection: binding) {
                ForEach(range, id: \.self) { value in
                    Text("\(value)").tag(value)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityIdentifier(identifier)
            Text(unit)
                .foregroundStyle(.secondary)
        }
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
    NavigationStack { SimpleTimerView() }
}
