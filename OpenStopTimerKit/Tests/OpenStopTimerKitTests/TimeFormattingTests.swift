import Testing
@testable import OpenStopTimerKit

struct TimeFormattingTests {
    // MARK: - clock() — static/settled values, nearest-rounding

    @Test func clockFormatsMinutesAndSeconds() {
        #expect(TimeFormatting.clock(75) == "01:15")
        #expect(TimeFormatting.clock(0) == "00:00")
        #expect(TimeFormatting.clock(59) == "00:59")
        #expect(TimeFormatting.clock(60) == "01:00")
    }

    @Test func clockRollsOverToHoursAtOrAboveThreeThousandSixHundredSeconds() {
        #expect(TimeFormatting.clock(3599) == "59:59")
        #expect(TimeFormatting.clock(3600) == "1:00:00")
        #expect(TimeFormatting.clock(3661) == "1:01:01")
        #expect(TimeFormatting.clock(7325) == "2:02:05")
    }

    @Test func clockRoundsToNearestWholeSecond() {
        #expect(TimeFormatting.clock(42.4) == "00:42")
        #expect(TimeFormatting.clock(42.5) == "00:43", "round-half-away-from-zero")
        #expect(TimeFormatting.clock(42.6) == "00:43")
    }

    @Test func clockClampsNegativeToZero() {
        #expect(TimeFormatting.clock(-5) == "00:00")
    }

    // MARK: - countdownClock() — live countdowns, ceiling

    /// The core correctness property this whole function exists for: with
    /// *any* fractional time still remaining in the current displayed
    /// second, the countdown must keep showing that second — it only
    /// flips down once truly at or under the next whole-second boundary.
    /// Using nearest-rounding instead (the bug this fixes) would flip the
    /// display up to 0.5s *before* that boundary was actually reached.
    @Test func countdownClockNeverFlipsBeforeTheTrueWholeSecondBoundary() {
        #expect(TimeFormatting.countdownClock(10.0) == "00:10")
        #expect(TimeFormatting.countdownClock(9.99) == "00:10")
        #expect(TimeFormatting.countdownClock(9.5) == "00:10", "would be 00:09 under nearest-rounding — that's the bug")
        #expect(TimeFormatting.countdownClock(9.01) == "00:10")
        #expect(TimeFormatting.countdownClock(9.0) == "00:09", "exactly on the boundary: the 9th second has fully elapsed")
        #expect(TimeFormatting.countdownClock(8.99) == "00:09")
    }

    @Test func countdownClockReachesZeroExactlyAtZero() {
        #expect(TimeFormatting.countdownClock(0.5) == "00:01")
        #expect(TimeFormatting.countdownClock(0.01) == "00:01")
        #expect(TimeFormatting.countdownClock(0.0) == "00:00")
    }

    @Test func countdownClockRollsOverToHours() {
        #expect(TimeFormatting.countdownClock(3600.5) == "1:00:01")
        #expect(TimeFormatting.countdownClock(3600.0) == "1:00:00")
    }

    @Test func countdownClockClampsNegativeToZero() {
        #expect(TimeFormatting.countdownClock(-5) == "00:00")
    }

    // MARK: - clockWithTenths()

    @Test func clockWithTenthsFormatsMinutesSecondsAndOneDecimal() {
        #expect(TimeFormatting.clockWithTenths(75.4) == "01:15.4")
        #expect(TimeFormatting.clockWithTenths(0) == "00:00.0")
        #expect(TimeFormatting.clockWithTenths(59.95) == "01:00.0", "rounds to the nearest tenth, carrying into the next second")
    }

    @Test func clockWithTenthsClampsNegativeToZero() {
        #expect(TimeFormatting.clockWithTenths(-1.5) == "00:00.0")
    }
}
