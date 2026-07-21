import SwiftUI
import OpenStopTimerKit

/// A pacing aid for track running: one huge number counting up modulo the
/// configured interval length (e.g. 0...41 for a 42s split), so a runner can
/// hear where they should be without looking at a watch. Deliberately
/// minimal — no colors, no upcoming-steps strip, just the number plus Back /
/// Settings / Play, matching the "just a big screen with one number" brief.
struct MetronomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var model: MetronomeModel
    @State private var isEditingSettings = false

    init(appState: AppState) {
        _model = State(initialValue: MetronomeModel(settings: appState.metronomeSettings, appearance: appState.globalAppearance))
    }

    var body: some View {
        AdaptiveTimerLayout {
            display
        } controls: {
            controls
        }
        // A real title while idle (so Home navigation reads normally), then
        // blank + hidden entirely once a session starts — every pixel
        // matters for the number once you're actually pacing against it.
        .navigationTitle(model.hasStarted ? "" : "Metronome")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(model.hasStarted ? .hidden : .visible, for: .navigationBar)
        .keepScreenAwake(while: model.isRunning || model.isCountingDown)
        // The number changes every second; a snappy, non-animated update
        // reads better than SwiftUI's default cross-fade on every change.
        .transaction { $0.disablesAnimations = true }
        .onAppear { model.appearance = appState.globalAppearance }
        .onChange(of: appState.globalAppearance) { _, newValue in model.appearance = newValue }
        .sheet(isPresented: $isEditingSettings) {
            NavigationStack {
                MetronomeSettingsView(settings: appState.metronomeSettings) { newSettings in
                    appState.metronomeSettings = newSettings
                    model.updateSettings(newSettings)
                }
            }
        }
    }

    private var display: some View {
        FillHeightText(text: model.displayNumber, fillFraction: 0.85)
            .foregroundStyle(.primary)
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // UI tests read the raw digits back via `.value` (same
            // convention as `BigTimeText`), keeping `.label` a
            // spoken-friendly VoiceOver phrase instead.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
            .accessibilityValue(model.displayNumber)
            .accessibilityIdentifier("metronome.display")
    }

    private var controls: some View {
        HStack(spacing: 28) {
            circularButton(systemImage: "chevron.left", identifier: "metronome.backButton") {
                dismiss()
            }
            if !model.hasStarted {
                circularButton(systemImage: "gearshape", identifier: "metronome.settingsButton") {
                    isEditingSettings = true
                }
            }
            primaryButton
        }
    }

    private var primaryButton: some View {
        Button(action: primaryAction) {
            Image(systemName: primaryIcon)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 80, height: 80)
                .background(Circle().fill(primaryColor))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(primaryAccessibilityLabel)
        .accessibilityIdentifier("metronome.primaryButton")
    }

    private var primaryIcon: String {
        if model.isCountingDown { return "xmark" }
        if !model.hasStarted || model.isPaused { return "play.fill" }
        return "pause.fill"
    }

    private var primaryAccessibilityLabel: String {
        if model.isCountingDown { return "Cancel" }
        if !model.hasStarted || model.isPaused { return "Start" }
        return "Pause"
    }

    private var primaryColor: Color {
        if model.isCountingDown { return .red }
        if !model.hasStarted || model.isPaused { return .green }
        return .orange
    }

    private func circularButton(systemImage: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 52, height: 52)
                .background(Circle().fill(.thinMaterial))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private func primaryAction() {
        if model.isCountingDown {
            model.reset()
        } else if !model.hasStarted {
            // The only way to start is with the 10s lead-in: give the runner
            // time to pocket the phone and hear "3, 2, 1, go" before they
            // need to actually move.
            model.start(leadInSeconds: 10)
        } else {
            model.togglePause()
        }
    }
}

#Preview {
    NavigationStack {
        MetronomeView(appState: AppState())
    }
}
