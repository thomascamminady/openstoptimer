import Foundation

/// A metronome's two knobs: how long one lap/interval is, and how far
/// before/after that mark to also tick — e.g. "beep every 42s, with a
/// warning tick at 41s and 43s" for pacing a run against a known split time.
/// Both fields are always kept in a valid, mutually-consistent range, so
/// nothing downstream (the engine, the UI) needs to re-validate them.
public struct MetronomeSettings: Codable, Hashable, Sendable {
    public static let cycleSecondsRange = 10...100
    /// Upper bound on the offset itself; the *effective* max is also capped
    /// below half the cycle length so the pre/post ticks never collide with
    /// each other or with the main mark (see `maxOffsetSeconds(forCycleSeconds:)`).
    public static let maxOffsetSecondsCeiling = 5

    public var cycleSeconds: Int
    public var offsetSeconds: Int

    public init(cycleSeconds: Int = 42, offsetSeconds: Int = 1) {
        let clampedCycle = Self.clamp(cycleSeconds, to: Self.cycleSecondsRange)
        self.cycleSeconds = clampedCycle
        self.offsetSeconds = Self.clamp(offsetSeconds, to: 0...Self.maxOffsetSeconds(forCycleSeconds: clampedCycle))
    }

    /// The largest offset that keeps the pre/post ticks distinct from the
    /// main 0-mark and from each other.
    public static func maxOffsetSeconds(forCycleSeconds cycleSeconds: Int) -> Int {
        max(0, min(maxOffsetSecondsCeiling, cycleSeconds / 2 - 1))
    }

    /// Returns a copy with `cycleSeconds` updated, re-clamping `offsetSeconds`
    /// against the new cycle length if it no longer fits.
    public func settingCycleSeconds(_ newValue: Int) -> MetronomeSettings {
        MetronomeSettings(cycleSeconds: newValue, offsetSeconds: offsetSeconds)
    }

    /// Returns a copy with `offsetSeconds` updated (clamped to what the
    /// current cycle length allows).
    public func settingOffsetSeconds(_ newValue: Int) -> MetronomeSettings {
        MetronomeSettings(cycleSeconds: cycleSeconds, offsetSeconds: newValue)
    }

    /// True at second 0 of the cycle — the primary "you should be here" mark.
    public func isMarkSecond(_ secondsIntoCycle: Int) -> Bool {
        secondsIntoCycle == 0
    }

    /// True at the configured lead/lag seconds around the mark (e.g. 41 and 1
    /// for a 42s cycle with a 1s offset) — the "bip ... BEEP ... bip" warning
    /// ticks either side of the main beep.
    public func isWarningSecond(_ secondsIntoCycle: Int) -> Bool {
        guard offsetSeconds > 0 else { return false }
        return secondsIntoCycle == offsetSeconds || secondsIntoCycle == cycleSeconds - offsetSeconds
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
