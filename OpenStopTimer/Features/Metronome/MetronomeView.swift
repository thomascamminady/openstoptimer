import SwiftUI
import OpenStopTimerKit

/// A pacing aid for track running: one huge number counting up modulo the
/// configured interval length (e.g. 0...41 for a 42s split), ringed by a
/// sub-second progress arc (which third of the current second, coarse and
/// color-coded) plus a small decimal-second readout underneath for anyone
/// who wants finer precision. Deliberately minimal otherwise — just the
/// number plus Back / Settings / Play, the last always centered regardless
/// of whether Settings is showing.
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
        GeometryReader { proxy in
            let side = max(0, min(proxy.size.width, proxy.size.height) - 24)
            let ringWidth = max(10, side * 0.035)
            ZStack {
                SubSecondProgressRing(progress: model.progressWithinSecond, lineWidth: ringWidth)
                VStack(spacing: side * 0.015) {
                    FillHeightText(text: model.displayNumber, fillFraction: 0.6)
                        .frame(height: side * 0.6)
                    // A touch more precision than the ring's 3 coarse
                    // thirds, for anyone who wants it — sized relative to
                    // the ring itself (not a tiny fixed label) so it's
                    // actually legible, and reserved so the number doesn't
                    // shift when it appears.
                    Text(model.decimalSecondText)
                        .font(.system(size: side * 0.14, design: .default))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .opacity(model.hasStarted ? 1 : 0)
                        .accessibilityHidden(true)
                }
                .padding(ringWidth * 2.2)
            }
            .foregroundStyle(.primary)
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // UI tests read the raw digits back via `.value` (same
            // convention as `BigTimeText`), keeping `.label` a
            // spoken-friendly VoiceOver phrase instead.
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel)
            .accessibilityValue(model.displayNumber)
            .accessibilityIdentifier("metronome.display")
        }
    }

    private var controls: some View {
        ZStack {
            CircularIconButton(systemImage: primaryIcon, style: .primary(color: primaryColor), action: primaryAction)
                .accessibilityLabel(primaryAccessibilityLabel)
                .accessibilityIdentifier("metronome.primaryButton")
            HStack {
                CircularIconButton(systemImage: "chevron.left", style: .secondary) {
                    dismiss()
                }
                .accessibilityIdentifier("metronome.backButton")
                Spacer()
                if !model.hasStarted {
                    CircularIconButton(systemImage: "gearshape", style: .secondary) {
                        isEditingSettings = true
                    }
                    .accessibilityIdentifier("metronome.settingsButton")
                }
            }
        }
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

    private func primaryAction() {
        if model.isCountingDown {
            model.reset()
        } else if !model.hasStarted {
            // The lead-in (configurable in Settings, default 10s) gives the
            // runner time to pocket the phone and hear "3, 2, 1, go" before
            // they need to actually move.
            model.start()
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
