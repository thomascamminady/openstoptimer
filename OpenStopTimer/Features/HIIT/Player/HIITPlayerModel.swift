import Foundation
import Observation
import OpenStopTimerKit

@MainActor
@Observable
final class HIITPlayerModel {
    let workout: HIITWorkout
    var appearance: AppearanceConfig

    private(set) var engine: PhaseSequenceEngine

    // Tracked, stored mirrors of `engine`'s state. `PhaseSequenceEngine` is a
    // plain (non-Observable) class, so calling e.g. `engine.start()` mutates
    // it in place without ever reassigning the `engine` property itself —
    // @Observable only notices writes to *its own* stored properties, so
    // without these mirrors + `syncFromEngine()` after every engine mutation,
    // the view would never re-render when the session starts/pauses/skips.
    private(set) var hasStarted = false
    private(set) var isPaused = false
    private(set) var isRunning = false
    private(set) var currentStep: WorkoutStep?
    private(set) var nextStep: WorkoutStep?
    private(set) var displayedElapsedInStep: TimeInterval = 0
    private(set) var displayedRemainingInStep: TimeInterval = 0
    private(set) var currentStepIndex: Int = 0
    private(set) var isFinished: Bool = false

    private var tickTask: Task<Void, Never>?
    private var lastAnnouncedStepIndex: Int?
    private var lastTickWholeSecond: Int?

    init(workout: HIITWorkout, appearance: AppearanceConfig) {
        self.workout = workout
        self.appearance = appearance
        engine = PhaseSequenceEngine(steps: workout.expandedSteps())
        nextStep = engine.steps.first
    }

    var steps: [WorkoutStep] { engine.steps }

    func start() {
        engine.start()
        lastAnnouncedStepIndex = nil
        lastTickWholeSecond = nil
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

    func skipNext() {
        engine.skipToNextStep()
        syncFromEngine()
    }

    func skipPrevious() {
        engine.skipToPreviousStep()
        syncFromEngine()
    }

    func reset() {
        tickTask?.cancel()
        tickTask = nil
        engine = PhaseSequenceEngine(steps: workout.expandedSteps())
        hasStarted = false
        isPaused = false
        isRunning = false
        currentStep = nil
        nextStep = engine.steps.first
        displayedElapsedInStep = 0
        displayedRemainingInStep = 0
        currentStepIndex = 0
        isFinished = false
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.syncFromEngine()
                if self.isFinished { break }
                // 200ms: still feels instant for phase transitions (the
                // display only shows whole seconds anyway), but meaningfully
                // less accessibility-tree churn than 100ms.
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    /// Pulls the engine's current state into this model's tracked stored
    /// properties. Must be called after every mutation of `engine` (start,
    /// pause, resume, skip, or a tick) — see the comment on the mirrored
    /// properties above for why this can't just be computed on demand.
    private func syncFromEngine() {
        hasStarted = engine.hasStarted
        isPaused = engine.isPaused
        isRunning = engine.isRunning

        // Checked ahead of the `currentPosition` branch: a workout with zero
        // expanded steps (e.g. an imported file with an empty round group)
        // has no position at all, but must still be able to reach "finished"
        // rather than spin the tick loop forever.
        if engine.isFinished, !isFinished {
            isFinished = true
            SoundPlayer.shared.play(appearance.sound(for: .workoutComplete))
            if appearance.hapticsEnabled { Haptics.success() }
        }

        guard let position = engine.currentPosition else {
            currentStep = nil
            return
        }

        if position.stepIndex != lastAnnouncedStepIndex {
            lastAnnouncedStepIndex = position.stepIndex
            lastTickWholeSecond = nil
            SoundPlayer.shared.play(appearance.sound(for: .phaseStart))
            if appearance.hapticsEnabled { Haptics.impact() }
        } else if position.remainingInStep > 0, position.remainingInStep <= Double(appearance.tickLeadSeconds) {
            let wholeSecond = Int(position.remainingInStep.rounded(.up))
            if wholeSecond != lastTickWholeSecond {
                lastTickWholeSecond = wholeSecond
                SoundPlayer.shared.play(appearance.sound(for: .countdownTick))
            }
        }

        currentStep = position.step
        nextStep = engine.nextStep
        displayedElapsedInStep = position.elapsedInStep
        displayedRemainingInStep = position.remainingInStep
        currentStepIndex = position.stepIndex
    }

    /// Called from the view on `scenePhase` changes: an immediate refresh on
    /// returning to foreground, rather than waiting up to one tick interval
    /// for the display to catch up with wherever the (still Date-anchored,
    /// always-correct) engine actually is.
    func handleScenePhase(isActive: Bool) {
        guard isActive else { return }
        syncFromEngine()
    }
}
