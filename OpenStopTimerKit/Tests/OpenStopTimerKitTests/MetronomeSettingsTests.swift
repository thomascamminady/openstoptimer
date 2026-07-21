import Foundation
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

    @Test func isPreMarkWarningSecondOnlyAtTheLeadSecond() {
        let settings = MetronomeSettings(cycleSeconds: 42, offsetSeconds: 1)
        #expect(settings.isPreMarkWarningSecond(41), "1s before the 42s mark")
        #expect(!settings.isPreMarkWarningSecond(1))
        #expect(!settings.isPreMarkWarningSecond(0))
    }

    @Test func isPostMarkWarningSecondOnlyAtTheLagSecond() {
        let settings = MetronomeSettings(cycleSeconds: 42, offsetSeconds: 1)
        #expect(settings.isPostMarkWarningSecond(1), "1s after the mark")
        #expect(!settings.isPostMarkWarningSecond(41))
        #expect(!settings.isPostMarkWarningSecond(0))
    }

    @Test func zeroOffsetMeansNoWarningTicks() {
        let settings = MetronomeSettings(cycleSeconds: 42, offsetSeconds: 0)
        #expect(!settings.isPreMarkWarningSecond(41))
        #expect(!settings.isPostMarkWarningSecond(1))
    }

    @Test func initClampsLeadInSecondsToValidRange() {
        #expect(MetronomeSettings(leadInSeconds: -5).leadInSeconds == 0)
        #expect(MetronomeSettings(leadInSeconds: 60).leadInSeconds == 30)
        #expect(MetronomeSettings(leadInSeconds: 15).leadInSeconds == 15)
        #expect(MetronomeSettings().leadInSeconds == 10, "default should match the original fixed lead-in")
    }

    @Test func settingLeadInSecondsLeavesOtherFieldsUntouched() {
        let settings = MetronomeSettings(cycleSeconds: 30, offsetSeconds: 2, leadInSeconds: 10)
        let updated = settings.settingLeadInSeconds(5)
        #expect(updated.leadInSeconds == 5)
        #expect(updated.cycleSeconds == 30)
        #expect(updated.offsetSeconds == 2)
    }

    @Test func decodingOlderPersistedSettingsWithoutLeadInSecondsDefaultsToTen() throws {
        let legacyJSON = Data(#"{"cycleSeconds":30,"offsetSeconds":2}"#.utf8)
        let decoded = try JSONDecoder().decode(MetronomeSettings.self, from: legacyJSON)
        #expect(decoded.cycleSeconds == 30)
        #expect(decoded.offsetSeconds == 2)
        #expect(decoded.leadInSeconds == 10)
    }
}
