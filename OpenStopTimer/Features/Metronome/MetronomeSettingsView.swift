import SwiftUI
import OpenStopTimerKit

/// A small, self-contained editing session for the metronome's knobs —
/// deliberately just wheels (fast to dial in "42") and a stepper, so setting
/// up a run takes seconds, not a trip through the full Settings tab.
struct MetronomeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var settings: MetronomeSettings
    let onSave: (MetronomeSettings) -> Void

    init(settings: MetronomeSettings, onSave: @escaping (MetronomeSettings) -> Void) {
        _settings = State(initialValue: settings)
        self.onSave = onSave
    }

    var body: some View {
        Form {
            Section {
                Picker("Interval Length", selection: cycleSecondsBinding) {
                    ForEach(Array(MetronomeSettings.cycleSecondsRange), id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier("metronomeSettings.cycleSecondsPicker")
            } header: {
                Text("Beep Every (seconds)")
            }

            Section {
                Picker("Countdown Before Start", selection: leadInSecondsBinding) {
                    ForEach(Array(MetronomeSettings.leadInSecondsRange), id: \.self) { value in
                        Text("\(value)").tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier("metronomeSettings.leadInSecondsPicker")
            } header: {
                Text("Countdown Before Start (seconds)")
            } footer: {
                Text("Plays \"3, 2, 1, go\" in the final 3 seconds, so you can hear when to begin without looking at your phone. Set to 0 to start immediately.")
            }

            Section {
                Stepper(
                    "Warning Ticks: \u{00b1}\(settings.offsetSeconds)s",
                    value: offsetSecondsBinding,
                    in: 0...MetronomeSettings.maxOffsetSeconds(forCycleSeconds: settings.cycleSeconds)
                )
                .accessibilityIdentifier("metronomeSettings.offsetStepper")
            } footer: {
                Text("Also plays a shorter tick this many seconds before and after the main beep, so you can hear if you're early or late.")
            }
        }
        .navigationTitle("Metronome Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    onSave(settings)
                    dismiss()
                }
                .accessibilityIdentifier("metronomeSettings.doneButton")
            }
        }
    }

    private var cycleSecondsBinding: Binding<Int> {
        Binding(
            get: { settings.cycleSeconds },
            set: { settings = settings.settingCycleSeconds($0) }
        )
    }

    private var offsetSecondsBinding: Binding<Int> {
        Binding(
            get: { settings.offsetSeconds },
            set: { settings = settings.settingOffsetSeconds($0) }
        )
    }

    private var leadInSecondsBinding: Binding<Int> {
        Binding(
            get: { settings.leadInSeconds },
            set: { settings = settings.settingLeadInSeconds($0) }
        )
    }
}

#Preview {
    NavigationStack {
        MetronomeSettingsView(settings: MetronomeSettings()) { _ in }
    }
}
