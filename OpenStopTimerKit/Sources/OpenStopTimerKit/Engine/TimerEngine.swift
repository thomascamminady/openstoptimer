import Foundation

/// A `Date`-anchored count-up or count-down primitive. `elapsed` is always
/// computed from `now() - start - accumulatedPause`, never from tick counts,
/// so it is instantly correct after any amount of backgrounding — there is no
/// state to reconcile on foreground return, just a fresh read.
///
/// Not thread-safe by design: intended to be owned and driven from a single
/// `@MainActor` view model.
public final class TimerEngine {
    public enum Direction: Sendable {
        case countUp
        case countDown(duration: TimeInterval)
    }

    private let clock: WallClock
    public let direction: Direction

    private var startDate: Date?
    private var accumulatedPause: TimeInterval = 0
    private var pauseStartedAt: Date?
    private(set) var finishedAtElapsed: TimeInterval?

    public init(direction: Direction, clock: WallClock = SystemWallClock()) {
        self.direction = direction
        self.clock = clock
    }

    public var isRunning: Bool { startDate != nil && pauseStartedAt == nil && finishedAtElapsed == nil }
    public var isPaused: Bool { pauseStartedAt != nil }
    public var hasStarted: Bool { startDate != nil }

    public var totalDuration: TimeInterval? {
        if case .countDown(let duration) = direction { return duration }
        return nil
    }

    /// Elapsed time since start, excluding paused time. Frozen once finished.
    public var elapsed: TimeInterval {
        if let finishedAtElapsed { return finishedAtElapsed }
        guard let startDate else { return 0 }
        let pausedSoFar = accumulatedPause + (pauseStartedAt.map { clock.now().timeIntervalSince($0) } ?? 0)
        let raw = clock.now().timeIntervalSince(startDate) - pausedSoFar
        if let totalDuration, raw >= totalDuration {
            return totalDuration
        }
        return max(0, raw)
    }

    /// Remaining time for a count-down engine; `nil` for count-up.
    public var remaining: TimeInterval? {
        guard let totalDuration else { return nil }
        return max(0, totalDuration - elapsed)
    }

    public var isFinished: Bool {
        if let totalDuration { return elapsed >= totalDuration }
        return finishedAtElapsed != nil
    }

    public func start() {
        guard startDate == nil else { return }
        startDate = clock.now()
        accumulatedPause = 0
        pauseStartedAt = nil
        finishedAtElapsed = nil
    }

    public func pause() {
        guard isRunning else { return }
        pauseStartedAt = clock.now()
    }

    public func resume() {
        guard let pauseStartedAt else { return }
        accumulatedPause += clock.now().timeIntervalSince(pauseStartedAt)
        self.pauseStartedAt = nil
    }

    /// Stops a count-up engine and freezes `elapsed` at its current value
    /// (used e.g. by the simple stopwatch's Stop button).
    public func finish() {
        guard finishedAtElapsed == nil else { return }
        finishedAtElapsed = elapsed
    }

    public func reset() {
        startDate = nil
        accumulatedPause = 0
        pauseStartedAt = nil
        finishedAtElapsed = nil
    }

    /// Wall-clock timestamp at which this engine will finish, given its
    /// current state — used to schedule background notifications. `nil` if
    /// not running or not a count-down engine.
    public var projectedFinishDate: Date? {
        guard isRunning, let remaining else { return nil }
        return clock.now().addingTimeInterval(remaining)
    }
}
