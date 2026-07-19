import SwiftUI
import OpenStopTimerKit

/// Global appearance defaults for HIIT and Lap Stopwatch: phase colors,
/// text scale, current/next layout ratio, sounds, and haptics. A workout can
/// still override any of this individually — these are just the fallbacks.
struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState

        Form {
            Section("Phase Colors") {
                ForEach(PhaseKind.allCases) { phase in
                    ColorPicker(phase.displayName, selection: SettingsModel.colorBinding($appState.globalAppearance, for: phase))
                }
            }

            Section("Display") {
                VStack(alignment: .leading) {
                    Text("Text Size: \(String(format: "%.1fx", appState.globalAppearance.fontScale))")
                    Slider(value: $appState.globalAppearance.fontScale, in: 0.6...1.8, step: 0.1)
                }
                VStack(alignment: .leading) {
                    Text("Current / Next Balance")
                    Slider(value: $appState.globalAppearance.currentNextRatio, in: 0.5...0.95, step: 0.05)
                }
            }

            Section("Sound") {
                Toggle("Sounds Enabled", isOn: $appState.globalAppearance.soundsEnabled)
                    .accessibilityIdentifier("settings.soundsEnabledToggle")
                if appState.globalAppearance.soundsEnabled {
                    ForEach(SoundEvent.allCases) { event in
                        Picker(event.displayName, selection: SettingsModel.soundBinding($appState.globalAppearance, for: event)) {
                            ForEach(SoundChoice.allCases) { choice in
                                Text(choice.displayName).tag(choice)
                            }
                        }
                    }
                    Stepper(
                        "Countdown Tick Lead: \(appState.globalAppearance.tickLeadSeconds)s",
                        value: $appState.globalAppearance.tickLeadSeconds,
                        in: 0...10
                    )
                }
            }

            Section("Haptics") {
                Toggle("Haptics Enabled", isOn: $appState.globalAppearance.hapticsEnabled)
            }

            Section {
                Button("Reset to Defaults", role: .destructive) {
                    appState.globalAppearance = .default
                }
                .accessibilityIdentifier("settings.resetButton")
            }

            Section("About") {
                LabeledContent("OpenStopTimer", value: "1.0")
                Text("Open source, no ads, no tracking. MIT licensed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environment(AppState())
}
