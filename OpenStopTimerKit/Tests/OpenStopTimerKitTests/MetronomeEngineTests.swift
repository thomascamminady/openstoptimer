import Testing
@testable import OpenStopTimerKit

struct MetronomeEngineTests {
    @Test func idleBeforeStart() {
        let engine = MetronomeEngine(cycleSeconds: 42)
        #expect(engine.phase == .idle)
        #expect(!engine.hasStarted)
    }

    @Test func immediateStartRunsFromZero() {
        let clock = FakeClock()
        let engine = MetronomeEngine(cycleSeconds: 42, clock: clock)
        engine.start()
        #expect(engine.phase == .running(secondsIntoCycle: 0))
        clock.advance(by: 5)
        #expect(engine.phase == .running(secondsIntoCycle: 5))
    }

    @Test func wrapsAtCycleBoundary() {
        let clock = FakeClock()
        let engine = MetronomeEngine(cycleSeconds: 10, clock: clock)
        engine.start()
        clock.advance(by: 9.9)
        #expect(engine.phase == .running(secondsIntoCycle: 9))
        clock.advance(by: 0.1) // exactly 10s elapsed -> wraps back to 0
        #expect(engine.phase == .running(secondsIntoCycle: 0))
        clock.advance(by: 15) // 25s total elapsed, 25 % 10 == 5
        #expect(engine.phase == .running(secondsIntoCycle: 5))
    }

    @Test func leadInCountsDownThenFlipsStraightToRunning() {
        let clock = FakeClock()
        let engine = MetronomeEngine(cycleSeconds: 42, clock: clock)
        engine.start(leadInSeconds: 10)
        #expect(engine.phase == .leadIn(secondsRemaining: 10))
        clock.advance(by: 6.5)
        #expect(engine.phase == .leadIn(secondsRemaining: 4))
        clock.advance(by: 3.4) // 9.9s total, still just inside the lead-in
        #expect(engine.phase == .leadIn(secondsRemaining: 1))
        clock.advance(by: 0.1) // exactly 10s -> the "go" instant, cycle starts at 0
        #expect(engine.phase == .running(secondsIntoCycle: 0))
    }

    @Test func pauseFreezesAndResumeContinuesCorrectly() {
        let clock = FakeClock()
        let engine = MetronomeEngine(cycleSeconds: 42, clock: clock)
        engine.start()
        clock.advance(by: 10)
        engine.pause()
        #expect(engine.isPaused)
        #expect(engine.phase == .paused(secondsIntoCycle: 10))
        clock.advance(by: 100) // simulate a long backgrounding while paused
        #expect(engine.phase == .paused(secondsIntoCycle: 10))
        engine.resume()
        #expect(engine.phase == .running(secondsIntoCycle: 10))
        clock.advance(by: 3)
        #expect(engine.phase == .running(secondsIntoCycle: 13))
    }

    @Test func pauseIsANoOpDuringLeadIn() {
        let clock = FakeClock()
        let engine = MetronomeEngine(cycleSeconds: 42, clock: clock)
        engine.start(leadInSeconds: 10)
        engine.pause()
        #expect(!engine.isPaused)
        clock.advance(by: 5)
        #expect(engine.phase == .leadIn(secondsRemaining: 5))
    }

    @Test func resetReturnsToIdle() {
        let clock = FakeClock()
        let engine = MetronomeEngine(cycleSeconds: 42, clock: clock)
        engine.start()
        clock.advance(by: 5)
        engine.reset()
        #expect(engine.phase == .idle)
        #expect(!engine.hasStarted)
    }

    @Test func initClampsCycleSecondsToValidRange() {
        #expect(MetronomeEngine(cycleSeconds: 3).cycleSeconds == 10)
        #expect(MetronomeEngine(cycleSeconds: 500).cycleSeconds == 100)
        #expect(MetronomeEngine(cycleSeconds: 42).cycleSeconds == 42)
    }
}
