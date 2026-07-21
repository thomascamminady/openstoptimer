import Testing
@testable import OpenStopTimerKit

struct MetronomeSettingsTests {
    @Test func initClampsCycleSecondsToValidRange() {
        #expect(MetronomeSettings(cycleSeconds: 3).cycleSeconds == 10)
        #expect(MetronomeSettings(cycleSeconds: 500).cycleSeconds == 100)
        #expect(MetronomeSettings(cycleSeconds: 42).cycleSeconds == 42)
    }

    @Test func initClampsOffsetSecondsToHalfTheCycleAndTheCeiling() {
        // 10s cycle: half - 1 == 4, well under the 5s ceiling.
        #expect(MetronomeSettings(cycleSeconds: 10, offsetSeconds: 4).offsetSeconds == 4)
        #expect(MetronomeSettings(cycleSeconds: 10, offsetSeconds: 4).offsetSeconds == 4)
        #expect(MetronomeSettings(cycleSeconds: 10, offsetSeconds: 100).offsetSeconds == 4)
        // 100s cycle: half - 1 == 49, way above the ceiling, so the 5s cap wins.
        #expect(MetronomeSettings(cycleSeconds: 100, offsetSeconds: 5).offsetSeconds == 5)
        #expect(MetronomeSettings(cycleSeconds: 100, offsetSeconds: 20).offsetSeconds == 5)
        #expect(MetronomeSettings(cycleSeconds: 10, offsetSeconds: -3).offsetSeconds == 0)
    }

    @Test func settingCycleSecondsReclampsOffset() {
        let settings = MetronomeSettings(cycleSeconds: 100, offsetSeconds: 5)
        let shrunk = settings.settingCycleSeconds(10)
        #expect(shrunk.cycleSeconds == 10)
        #expect(shrunk.offsetSeconds == 4, "offset should re-clamp down when the cycle shrinks under it")
    }

    @Test func isMarkSecondOnlyAtZero() {
        let settings = MetronomeSettings(cycleSeconds: 42, offsetSeconds: 1)
        #expect(settings.isMarkSecond(0))
        #expect(!settings.isMarkSecond(1))
        #expect(!settings.isMarkSecond(41))
    }

    @Test func isWarningSecondAtOffsetBeforeAndAfterTheMark() {
        let settings = MetronomeSettings(cycleSeconds: 42, offsetSeconds: 1)
        #expect(settings.isWarningSecond(41), "1s before the 42s mark")
        #expect(settings.isWarningSecond(1), "1s after the mark")
        #expect(!settings.isWarningSecond(0))
        #expect(!settings.isWarningSecond(20))
    }

    @Test func zeroOffsetMeansNoWarningTicks() {
        let settings = MetronomeSettings(cycleSeconds: 42, offsetSeconds: 0)
        #expect(!settings.isWarningSecond(41))
        #expect(!settings.isWarningSecond(1))
    }
}
