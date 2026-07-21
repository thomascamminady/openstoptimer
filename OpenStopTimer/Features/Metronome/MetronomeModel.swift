import Foundation
import Observation
import UIKit
import OpenStopTimerKit

/// Drives a `MetronomeEngine` and translates its phase into sound/haptic
/// events: short ticks for the last 3 seconds of a lead-in, a distinct "go"
/// cue the instant a lead-in hands off to running, a stronger beep at the
/// cycle's 0-mark, and quieter warning ticks at the configured offset either
/// side of it. Deliberately sound/haptics only — this app never schedules a
/// system notification, so nothing here fires while backgrounded.
@MainActor
@Observable
final class MetronomeModel {
    var appearance: AppearanceConfig
    private(set) var settings: MetronomeSettings

    private var engine: MetronomeEngine

    // Tracked, stored mirror of `engine.phase` — `MetronomeEngine` is a plain
    // (non-Observable) class, so mutating it in place wouldn't otherwise
    // trigger a SwiftUI re-render (same reasoning as `HIITPlayerModel`).
    private(set) var phase: MetronomeEngine.Phase = .idle

    private var tickTask: Task<Void, Never>?
    private var lastAnnouncedLeadInSecond: Int?
    private var lastAnnouncedCycleSecond: Int?
    /// True once the "go" cue has fired for the current run — an immediate
    /// (no-lead-in) start marks this true up front so no cue plays at t=0.
    private var hasFiredGo = false

    init(settings: MetronomeSettings, appearance: AppearanceConfig) {
        self.settings = settings
        self.appearance = appearance
        engine = MetronomeEngine(cycleSeconds: settings.cycleSeconds)
    }

    var hasStarted: Bool { engine.hasStarted }
    var isRunning: Bool { engine.isRunning }
    var isPaused: Bool { engine.isPaused }
    var isCountingDown: Bool {
        if case .leadIn = phase { return true }
        return false
    }

    /// Before starting, shows the configured interval length (so the number
    /// on screen never visually jumps in size once a session actually
    /// starts); during the lead-in, the countdown itself; while
    /// running/paused, seconds into the current cycle, zero-padded so the
    /// digit count — and therefore the size the text renders at — stays
    /// constant as it counts.
    var displayNumber: String {
        switch phase {
        case .idle: String(format: "%02d", settings.cycleSeconds)
        case .leadIn(let secondsRemaining): String(secondsRemaining)
        case .running(let secondsIntoCycle), .paused(let secondsIntoCycle):
            String(format: "%02d", secondsIntoCycle)
        }
    }

    var accessibilityLabel: String {
        switch phase {
        case .idle: "Metronome set to \(settings.cycleSeconds) seconds"
        case .leadIn(let secondsRemaining): "Starting in \(secondsRemaining)"
        case .running(let secondsIntoCycle): "\(secondsIntoCycle) seconds into a \(settings.cycleSeconds) second interval"
        case .paused(let secondsIntoCycle): "Paused at \(secondsIntoCycle) seconds"
        }
    }

    /// Applies an edited settings value. While idle this also rebuilds the
    /// engine so the next `start()` uses the new cycle length; while running
    /// the cycle length a session already anchored to is left alone (only
    /// the *next* run picks up the change), matching the rest of the app's
    /// "can't reconfigure a session already in flight" convention.
    func updateSettings(_ newSettings: MetronomeSettings) {
        settings = newSettings
        guard !hasStarted else { return }
        engine = MetronomeEngine(cycleSeconds: newSettings.cycleSeconds)
    }

    func start(leadInSeconds: Int) {
        engine = MetronomeEngine(cycleSeconds: settings.cycleSeconds)
        lastAnnouncedLeadInSecond = nil
        lastAnnouncedCycleSecond = nil
        hasFiredGo = leadInSeconds <= 0
        engine.start(leadInSeconds: leadInSeconds)
        syncFromEngine()
        startTicking()
    }

    func togglePause() {
        if engine.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
        syncFromEngine()
    }

    func reset() {
        tickTask?.cancel()
        tickTask = nil
        engine.reset()
        phase = .idle
        lastAnnouncedLeadInSecond = nil
        lastAnnouncedCycleSecond = nil
        hasFiredGo = false
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.syncFromEngine()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func syncFromEngine() {
        let newPhase = engine.phase
        defer { phase = newPhase }

        switch newPhase {
        case .idle:
            break

        case .leadIn(let secondsRemaining):
            guard secondsRemaining != lastAnnouncedLeadInSecond else { break }
            lastAnnouncedLeadInSecond = secondsRemaining
            guard secondsRemaining <= 3 else { break }
            play(.beepShort)
            fireHaptic(.medium)

        case .running(let secondsIntoCycle):
            if !hasFiredGo {
                hasFiredGo = true
                lastAnnouncedCycleSecond = secondsIntoCycle
                play(.whistle)
                fireHaptic(.heavy)
                break
            }
            guard secondsIntoCycle != lastAnnouncedCycleSecond else { break }
            lastAnnouncedCycleSecond = secondsIntoCycle
            if settings.isMarkSecond(secondsIntoCycle) {
                play(.beepDouble)
                fireHaptic(.heavy)
            } else if settings.isWarningSecond(secondsIntoCycle) {
                play(.beepShort)
                fireHaptic(.medium)
            }

        case .paused:
            break
        }
    }

    private func play(_ choice: SoundChoice) {
        guard appearance.soundsEnabled else { return }
        SoundPlayer.shared.play(choice)
    }

    private func fireHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard appearance.hapticsEnabled else { return }
        Haptics.impact(style)
    }
}
