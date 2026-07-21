import Foundation
import Observation
import UIKit
import OpenStopTimerKit

/// Drives a `MetronomeEngine` and translates its phase into sound/haptic
/// events: short ticks for the last 3 seconds of a lead-in, a distinct "go"
/// cue the instant a lead-in hands off to running, a longer beep at the
/// cycle's 0-mark, and quieter warning ticks at the configured offset either
/// side of it (suppressing the post-mark tick until a real mark has fired
/// once, so the very first cycle doesn't get a spurious beep on its heels
/// of the go cue). Deliberately sound/haptics only — this app never
/// schedules a system notification, so nothing here fires while backgrounded.
@MainActor
@Observable
final class MetronomeModel {
    var appearance: AppearanceConfig
    private(set) var settings: MetronomeSettings

    private var engine: MetronomeEngine

    // Tracked, stored mirrors of `engine`'s state — `MetronomeEngine` is a
    // plain (non-Observable) class, so mutating it in place wouldn't
    // otherwise trigger a SwiftUI re-render (same reasoning as
    // `HIITPlayerModel`).
    private(set) var phase: MetronomeEngine.Phase = .idle
    /// 0..<1 — how far into the currently-displayed second we are, for the
    /// sub-second progress ring. See `MetronomeEngine.fractionalSecondProgress`.
    private(set) var progressWithinSecond: Double = 0

    private var tickTask: Task<Void, Never>?
    private var lastAnnouncedLeadInSecond: Int?
    private var lastAnnouncedCycleSecond: Int?
    /// True once the "go" cue has fired for the current run — an immediate
    /// (no-lead-in) start marks this true up front so no cue plays at t=0.
    private var hasFiredGo = false
    /// True once the main mark has fired at least once this run. The
    /// post-mark warning tick (e.g. "1s after the mark") is meaningless
    /// before that — it would otherwise fire ~`offsetSeconds` into the very
    /// first cycle, right on the heels of the go cue, which reads as a
    /// spurious extra beep rather than a warning about anything.
    private var hasReachedFirstMark = false

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

    /// One decimal place of `progressWithinSecond` (e.g. ".7") — a small
    /// supplementary readout under the ring for anyone who wants a touch
    /// more precision than the 3 coarse thirds the ring itself shows.
    var decimalSecondText: String {
        ".\(Int(progressWithinSecond * 10))"
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

    func start() {
        engine = MetronomeEngine(cycleSeconds: settings.cycleSeconds)
        lastAnnouncedLeadInSecond = nil
        lastAnnouncedCycleSecond = nil
        hasFiredGo = settings.leadInSeconds <= 0
        hasReachedFirstMark = false
        engine.start(leadInSeconds: settings.leadInSeconds)
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
        progressWithinSecond = 0
        lastAnnouncedLeadInSecond = nil
        lastAnnouncedCycleSecond = nil
        hasFiredGo = false
        hasReachedFirstMark = false
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.syncFromEngine()
                // 30ms rather than this app's usual 100-200ms tick interval:
                // a beep is only as "on time" as the polling that detects
                // the second boundary triggering it, and a runner pacing
                // against this needs tighter timing than a phase-transition
                // display does.
                try? await Task.sleep(for: .milliseconds(30))
            }
        }
    }

    private func syncFromEngine() {
        let newPhase = engine.phase
        defer {
            phase = newPhase
            progressWithinSecond = engine.fractionalSecondProgress
        }

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
                hasReachedFirstMark = true
                play(.beepLong)
                fireHaptic(.heavy)
            } else if settings.isPreMarkWarningSecond(secondsIntoCycle) {
                play(.beepShort)
                fireHaptic(.medium)
            } else if hasReachedFirstMark, settings.isPostMarkWarningSecond(secondsIntoCycle) {
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
