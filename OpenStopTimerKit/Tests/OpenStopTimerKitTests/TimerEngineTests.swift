import Testing
@testable import OpenStopTimerKit

struct TimerEngineTests {
    @Test func countUpElapsedTracksClock() {
        let clock = FakeClock()
        let engine = TimerEngine(direction: .countUp, clock: clock)
        engine.start()
        clock.advance(by: 5)
        #expect(abs(engine.elapsed - 5) < 0.001)
        clock.advance(by: 2.5)
        #expect(abs(engine.elapsed - 7.5) < 0.001)
    }

    @Test func countDownRemainingAndFinished() {
        let clock = FakeClock()
        let engine = TimerEngine(direction: .countDown(duration: 10), clock: clock)
        engine.start()
        clock.advance(by: 4)
        #expect(abs(engine.remaining! - 6) < 0.001)
        #expect(!engine.isFinished)

        clock.advance(by: 10)
        #expect(abs(engine.remaining! - 0) < 0.001)
        #expect(engine.isFinished)
    }

    @Test func pauseExcludesPausedTimeFromElapsed() {
        let clock = FakeClock()
        let engine = TimerEngine(direction: .countUp, clock: clock)
        engine.start()
        clock.advance(by: 3)
        engine.pause()
        clock.advance(by: 100) // simulate a long backgrounding while paused
        #expect(abs(engine.elapsed - 3) < 0.001)
        engine.resume()
        clock.advance(by: 2)
        #expect(abs(engine.elapsed - 5) < 0.001)
    }

    /// The core backgrounding-correctness guarantee: a single huge jump in
    /// wall-clock time (simulating the process being suspended for a long
    /// while) must be reflected correctly on the very next read, with no
    /// special-case reconciliation needed.
    @Test func largeClockJumpSelfCorrects() {
        let clock = FakeClock()
        let engine = TimerEngine(direction: .countDown(duration: 60), clock: clock)
        engine.start()
        clock.advance(by: 3600) // "backgrounded" for an hour
        #expect(engine.isFinished)
        #expect(abs(engine.remaining! - 0) < 0.001)
    }

    @Test func finishFreezesElapsedForCountUp() {
        let clock = FakeClock()
        let engine = TimerEngine(direction: .countUp, clock: clock)
        engine.start()
        clock.advance(by: 8)
        engine.finish()
        clock.advance(by: 100)
        #expect(abs(engine.elapsed - 8) < 0.001)
        #expect(engine.isFinished)
    }

    @Test func resetClearsState() {
        let clock = FakeClock()
        let engine = TimerEngine(direction: .countUp, clock: clock)
        engine.start()
        clock.advance(by: 5)
        engine.reset()
        #expect(engine.elapsed == 0)
        #expect(!engine.hasStarted)
    }
}
