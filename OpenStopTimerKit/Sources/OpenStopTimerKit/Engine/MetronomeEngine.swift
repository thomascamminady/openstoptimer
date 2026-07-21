import Foundation

/// Drives a repeating pace metronome: an optional lead-in countdown (e.g.
/// "starts in 10s"), then an indefinitely-repeating count from 0 up to
/// `cycleSeconds - 1` and back to 0. Like the other engines, `phase` is a
/// pure function of `(runAnchor, pause, now)` — a long backgrounding period
/// self-corrects on the very next read, with no reconciliation needed.
///
/// Deciding *which* seconds should actually beep (the main mark, the
/// pre/post warning ticks) is deliberately not this engine's job — that's
/// `MetronomeSettings.isMarkSecond`/`isWarningSecond`, applied by the caller
/// against `phase`'s `secondsIntoCycle` on each tick.
public final class MetronomeEngine {
    public enum Phase: Equatable, Sendable {
        case idle
        /// Counting down to the "go" moment; never reaches 0 — the instant
        /// it would, `phase` has already flipped to `.running(secondsIntoCycle: 0)`.
        case leadIn(secondsRemaining: Int)
        case running(secondsIntoCycle: Int)
        case paused(secondsIntoCycle: Int)
    }

    private let clock: WallClock
    public let cycleSeconds: Int

    /// The wall-clock instant `secondsIntoCycle` becomes (and then repeatedly
    /// returns to) 0 — set to "now" for an immediate start, or `leadInSeconds`
    /// in the future for a lead-in start.
    private var runAnchor: Date?
    private var pausedAt: Date?
    private var totalPaused: TimeInterval = 0

    public init(cycleSeconds: Int, clock: WallClock = SystemWallClock()) {
        self.cycleSeconds = min(
            max(cycleSeconds, MetronomeSettings.cycleSecondsRange.lowerBound),
            MetronomeSettings.cycleSecondsRange.upperBound
        )
        self.clock = clock
    }

    public var hasStarted: Bool { runAnchor != nil }

    public var isRunning: Bool {
        if case .running = phase { return true }
        return false
    }

    public var isPaused: Bool {
        if case .paused = phase { return true }
        return false
    }

    /// Starts (or restarts) the metronome. `leadInSeconds == 0` starts
    /// counting immediately; otherwise `phase` reports `.leadIn` until that
    /// many seconds have elapsed, at which point it flips straight to
    /// `.running(secondsIntoCycle: 0)` — no separate "go" phase to poll for,
    /// callers detect that edge by noticing `phase` changed from `.leadIn`
    /// to `.running` between two ticks.
    public func start(leadInSeconds: Int = 0) {
        let now = clock.now()
        runAnchor = now.addingTimeInterval(max(0, TimeInterval(leadInSeconds)))
        pausedAt = nil
        totalPaused = 0
    }

    /// Only takes effect while actually running — pausing mid-lead-in isn't
    /// supported (there's nothing useful to freeze; just let it finish or
    /// call `reset()` to cancel outright).
    public func pause() {
        guard case .running = phase else { return }
        pausedAt = clock.now()
    }

    public func resume() {
        guard let pausedAt else { return }
        totalPaused += clock.now().timeIntervalSince(pausedAt)
        self.pausedAt = nil
    }

    public func reset() {
        runAnchor = nil
        pausedAt = nil
        totalPaused = 0
    }

    public var phase: Phase {
        guard let runAnchor else { return .idle }
        let referenceNow = pausedAt ?? clock.now()
        if referenceNow < runAnchor {
            let remaining = Int(ceil(runAnchor.timeIntervalSince(referenceNow)))
            return .leadIn(secondsRemaining: max(1, remaining))
        }
        let elapsedSinceGo = referenceNow.timeIntervalSince(runAnchor) - totalPaused
        let secondsIntoCycle = Int(max(0, elapsedSinceGo)) % cycleSeconds
        return pausedAt != nil ? .paused(secondsIntoCycle: secondsIntoCycle) : .running(secondsIntoCycle: secondsIntoCycle)
    }

    /// How far into the currently-displayed second we are (0..<1) — the
    /// same second `phase` reports via `secondsRemaining`/`secondsIntoCycle`,
    /// just with sub-second resolution, so a UI can animate a ring/arc that
    /// visually resets in lockstep with the integer changing. Frozen while
    /// paused (same `referenceNow` substitution as `phase`); `0` before
    /// starting.
    public var fractionalSecondProgress: Double {
        guard let runAnchor else { return 0 }
        let referenceNow = pausedAt ?? clock.now()
        if referenceNow < runAnchor {
            // Counting down: "elapsed within this displayed second" is the
            // complement of how far into the remaining-seconds fraction we
            // are, so the ring still visually *fills* rather than drains.
            let remainingFraction = runAnchor.timeIntervalSince(referenceNow).truncatingRemainder(dividingBy: 1)
            return (1 - remainingFraction).truncatingRemainder(dividingBy: 1)
        }
        let elapsedSinceGo = max(0, referenceNow.timeIntervalSince(runAnchor) - totalPaused)
        return elapsedSinceGo.truncatingRemainder(dividingBy: 1)
    }
}
