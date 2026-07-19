import Testing
@testable import OpenStopTimerKit

struct PhaseSequenceEngineTests {
    private func makeSteps() -> [WorkoutStep] {
        [
            WorkoutStep(name: "Prepare", kind: .prepare, duration: 5),
            WorkoutStep(name: "Work 1", kind: .work, duration: 20),
            WorkoutStep(name: "Rest 1", kind: .rest, duration: 10),
            WorkoutStep(name: "Work 2", kind: .work, duration: 20),
        ]
    }

    @Test func positionAtStart() {
        let clock = FakeClock()
        let engine = PhaseSequenceEngine(steps: makeSteps(), clock: clock)
        engine.start()
        let position = engine.currentPosition!
        #expect(position.stepIndex == 0)
        #expect(position.step.name == "Prepare")
        #expect(abs(position.elapsedInStep - 0) < 0.001)
    }

    @Test func positionAdvancesAcrossStepBoundaries() {
        let clock = FakeClock()
        let engine = PhaseSequenceEngine(steps: makeSteps(), clock: clock)
        engine.start()

        clock.advance(by: 5) // exactly at the Prepare -> Work 1 boundary
        #expect(engine.currentPosition!.step.name == "Work 1")
        #expect(abs(engine.currentPosition!.elapsedInStep - 0) < 0.001)

        clock.advance(by: 12) // 17s total: 12s into Work 1
        #expect(engine.currentPosition!.step.name == "Work 1")
        #expect(abs(engine.currentPosition!.elapsedInStep - 12) < 0.001)

        clock.advance(by: 30) // 47s total: Rest 1 ends at 35s, so 12s into Work 2
        #expect(engine.currentPosition!.step.name == "Work 2")
        #expect(abs(engine.currentPosition!.elapsedInStep - 12) < 0.001)
    }

    /// The whole point of computing position from prefix sums against
    /// wall-clock elapsed: an arbitrarily large jump (long backgrounding)
    /// lands on the correct step immediately, no per-tick catch-up needed.
    @Test func largeClockJumpLandsOnCorrectStep() {
        let clock = FakeClock()
        let steps = makeSteps()
        let engine = PhaseSequenceEngine(steps: steps, clock: clock)
        engine.start()
        clock.advance(by: 3600) // way past the end
        #expect(engine.isFinished)
        let position = engine.currentPosition!
        #expect(position.stepIndex == steps.count - 1)
        #expect(abs(position.remainingInStep - 0) < 0.001)
    }

    @Test func pauseFreezesPosition() {
        let clock = FakeClock()
        let engine = PhaseSequenceEngine(steps: makeSteps(), clock: clock)
        engine.start()
        clock.advance(by: 8) // 3s into Work 1
        engine.pause()
        clock.advance(by: 500)
        #expect(engine.currentPosition!.step.name == "Work 1")
        #expect(abs(engine.currentPosition!.elapsedInStep - 3) < 0.001)
        engine.resume()
        clock.advance(by: 1)
        #expect(abs(engine.currentPosition!.elapsedInStep - 4) < 0.001)
    }

    @Test func skipToNextStepJumpsToBoundary() {
        let clock = FakeClock()
        let engine = PhaseSequenceEngine(steps: makeSteps(), clock: clock)
        engine.start()
        clock.advance(by: 10) // 5s into Work 1
        engine.skipToNextStep()
        #expect(engine.currentPosition!.step.name == "Rest 1")
        #expect(abs(engine.currentPosition!.elapsedInStep - 0) < 0.001)
    }

    @Test func skipToPreviousStepRestartsCurrentPastThreshold() {
        let clock = FakeClock()
        let engine = PhaseSequenceEngine(steps: makeSteps(), clock: clock)
        engine.start()
        clock.advance(by: 15) // 10s into Work 1, past the 3s threshold
        engine.skipToPreviousStep()
        #expect(engine.currentPosition!.step.name == "Work 1")
        #expect(abs(engine.currentPosition!.elapsedInStep - 0) < 0.001)
    }

    @Test func skipToPreviousStepGoesBackWithinThreshold() {
        let clock = FakeClock()
        let engine = PhaseSequenceEngine(steps: makeSteps(), clock: clock)
        engine.start()
        clock.advance(by: 6) // 1s into Work 1, within the 3s threshold
        engine.skipToPreviousStep()
        #expect(engine.currentPosition!.step.name == "Prepare")
    }

    @Test func remainingTransitionsCount() {
        let clock = FakeClock()
        let steps = makeSteps()
        let engine = PhaseSequenceEngine(steps: steps, clock: clock)
        engine.start()
        // 3 remaining step boundaries + 1 final completion = 4
        #expect(engine.remainingTransitions().count == 4)
    }
}
