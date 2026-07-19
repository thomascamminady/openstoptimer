import Foundation

/// Drives a multi-phase step sequence (a HIIT workout's flattened steps).
/// Like `TimerEngine`, position is a pure function of `(anchor, pause, now)`
/// recomputed against a prefix-sum of step durations — so an arbitrarily long
/// backgrounding period self-corrects on the very next read, with no special
/// casing for how long the app was suspended.
public final class PhaseSequenceEngine {
    public struct Position: Equatable, Sendable {
        public let stepIndex: Int
        public let step: WorkoutStep
        public let elapsedInStep: TimeInterval
        public let remainingInStep: TimeInterval
    }

    private let clock: WallClock
    public let steps: [WorkoutStep]
    public let totalDuration: TimeInterval
    private let cumulativeStartOffsets: [TimeInterval]

    private var startDate: Date?
    private var accumulatedPause: TimeInterval = 0
    private var pauseStartedAt: Date?
    /// Manual adjustment applied on top of wall-clock elapsed, used to implement
    /// skip-forward/skip-backward without disturbing the pause bookkeeping.
    private var skipOffset: TimeInterval = 0

    public init(steps: [WorkoutStep], clock: WallClock = SystemWallClock()) {
        self.steps = steps
        self.clock = clock
        var offsets: [TimeInterval] = []
        var running: TimeInterval = 0
        for step in steps {
            offsets.append(running)
            running += step.duration
        }
        self.cumulativeStartOffsets = offsets
        self.totalDuration = running
    }

    public var isRunning: Bool { startDate != nil && pauseStartedAt == nil && !isFinished }
    public var isPaused: Bool { pauseStartedAt != nil }
    public var hasStarted: Bool { startDate != nil }
    public var isFinished: Bool { hasStarted && totalElapsed >= totalDuration }

    private var rawElapsed: TimeInterval {
        guard let startDate else { return 0 }
        let pausedSoFar = accumulatedPause + (pauseStartedAt.map { clock.now().timeIntervalSince($0) } ?? 0)
        return clock.now().timeIntervalSince(startDate) - pausedSoFar
    }

    /// Total elapsed time across the whole sequence, clamped to `[0, totalDuration]`.
    public var totalElapsed: TimeInterval {
        guard hasStarted else { return 0 }
        return min(max(0, rawElapsed + skipOffset), totalDuration)
    }

    public var currentPosition: Position? {
        guard hasStarted, !steps.isEmpty else { return nil }
        let elapsed = totalElapsed
        let index = Self.stepIndex(at: elapsed, offsets: cumulativeStartOffsets, steps: steps)
        let step = steps[index]
        let elapsedInStep = elapsed - cumulativeStartOffsets[index]
        return Position(
            stepIndex: index,
            step: step,
            elapsedInStep: elapsedInStep,
            remainingInStep: max(0, step.duration - elapsedInStep)
        )
    }

    public var nextStep: WorkoutStep? {
        guard let currentPosition else { return steps.first }
        let nextIndex = currentPosition.stepIndex + 1
        return nextIndex < steps.count ? steps[nextIndex] : nil
    }

    private static func stepIndex(at elapsed: TimeInterval, offsets: [TimeInterval], steps: [WorkoutStep]) -> Int {
        for index in stride(from: steps.count - 1, through: 0, by: -1) where elapsed >= offsets[index] {
            // Last step should hold its index even once elapsed == totalDuration.
            if index == steps.count - 1 { return index }
            if elapsed < offsets[index] + steps[index].duration || index == steps.count - 1 {
                return index
            }
        }
        return 0
    }

    public func start() {
        guard startDate == nil else { return }
        startDate = clock.now()
        accumulatedPause = 0
        pauseStartedAt = nil
        skipOffset = 0
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

    public func reset() {
        startDate = nil
        accumulatedPause = 0
        pauseStartedAt = nil
        skipOffset = 0
    }

    public func skipToNextStep() {
        guard let position = currentPosition else { return }
        let nextIndex = position.stepIndex + 1
        let target = nextIndex < steps.count ? cumulativeStartOffsets[nextIndex] : totalDuration
        jump(toOffset: target)
    }

    /// Mimics typical stopwatch/player behavior: within the first 3s of a step,
    /// jump to the start of the previous step; otherwise restart the current step.
    public func skipToPreviousStep() {
        guard let position = currentPosition else { return }
        let restartCurrent = position.elapsedInStep > 3
        let targetIndex = restartCurrent ? position.stepIndex : max(0, position.stepIndex - 1)
        jump(toOffset: cumulativeStartOffsets[targetIndex])
    }

    private func jump(toOffset target: TimeInterval) {
        guard hasStarted else { return }
        skipOffset = target - rawElapsed
    }

    /// Wall-clock timestamps and step indices for every remaining phase
    /// transition — used to schedule background notifications.
    public func remainingTransitions() -> [(date: Date, stepIndex: Int)] {
        guard isRunning else { return [] }
        let now = clock.now()
        let elapsed = totalElapsed
        var result: [(Date, Int)] = []
        for index in 0..<steps.count where cumulativeStartOffsets[index] > elapsed {
            let delay = cumulativeStartOffsets[index] - elapsed
            result.append((now.addingTimeInterval(delay), index))
        }
        if elapsed < totalDuration {
            result.append((now.addingTimeInterval(totalDuration - elapsed), steps.count))
        }
        return result
    }
}
