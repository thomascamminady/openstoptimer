import Testing
@testable import OpenStopTimerKit

struct AppearanceOverrideTests {
    @Test func emptyOverrideResolvesToBaseUnchanged() {
        let base = AppearanceConfig.default
        let resolved = AppearanceOverride().resolved(against: base)
        #expect(resolved == base)
    }

    @Test func overrideReplacesOnlyTouchedFields() {
        let base = AppearanceConfig.default
        var override = AppearanceOverride()
        override.fontScale = 2.0
        override.hapticsEnabled = false

        let resolved = override.resolved(against: base)
        #expect(resolved.fontScale == 2.0)
        #expect(resolved.hapticsEnabled == false)
        // Untouched fields fall through from base.
        #expect(resolved.currentNextRatio == base.currentNextRatio)
        #expect(resolved.tickLeadSeconds == base.tickLeadSeconds)
    }

    @Test func overridePhaseColorsMergeRatherThanReplaceWholeDictionary() {
        let base = AppearanceConfig.default
        var override = AppearanceOverride()
        override.phaseColors = [PhaseKind.work.rawValue: .black]

        let resolved = override.resolved(against: base)
        #expect(resolved.color(for: .work) == .black)
        // Other phases still fall back to their kind defaults.
        #expect(resolved.color(for: .rest) == PhaseKind.rest.defaultColor)
    }

    @Test func configColorAndSoundLookupFallBackToDefaults() {
        let config = AppearanceConfig.default
        #expect(config.color(for: .work) == PhaseKind.work.defaultColor)
        #expect(config.sound(for: .phaseStart) == SoundEvent.phaseStart.defaultSound)
    }

    @Test func soundsDisabledForcesNoneRegardlessOfChoice() {
        var config = AppearanceConfig.default
        config.soundsEnabled = false
        config.setSound(.bell, for: .workoutComplete)
        #expect(config.sound(for: .workoutComplete) == .none)
    }
}
