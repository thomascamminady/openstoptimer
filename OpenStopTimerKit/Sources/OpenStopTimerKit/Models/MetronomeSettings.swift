import Foundation

/// A metronome's knobs: how long one lap/interval is, how far before/after
/// that mark to also tick — e.g. "beep every 42s, with a warning tick at 41s
/// and 43s" — and how long a "starting in..." lead-in to give before the
/// first cycle begins. All fields are always kept in a valid,
/// mutually-consistent range, so nothing downstream (the engine, the UI)
/// needs to re-validate them.
public struct MetronomeSettings: Codable, Hashable, Sendable {
    public static let cycleSecondsRange = 10...100
    /// Upper bound on the offset itself; the *effective* max is also capped
    /// below half the cycle length so the pre/post ticks never collide with
    /// each other or with the main mark (see `maxOffsetSeconds(forCycleSeconds:)`).
    public static let maxOffsetSecondsCeiling = 5
    public static let leadInSecondsRange = 0...30

    public var cycleSeconds: Int
    public var offsetSeconds: Int
    public var leadInSeconds: Int

    public init(cycleSeconds: Int = 42, offsetSeconds: Int = 1, leadInSeconds: Int = 10) {
        let clampedCycle = Self.clamp(cycleSeconds, to: Self.cycleSecondsRange)
        self.cycleSeconds = clampedCycle
        self.offsetSeconds = Self.clamp(offsetSeconds, to: 0...Self.maxOffsetSeconds(forCycleSeconds: clampedCycle))
        self.leadInSeconds = Self.clamp(leadInSeconds, to: Self.leadInSecondsRange)
    }

    private enum CodingKeys: String, CodingKey {
        case cycleSeconds, offsetSeconds, leadInSeconds
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let cycleSeconds = try container.decode(Int.self, forKey: .cycleSeconds)
        let offsetSeconds = try container.decode(Int.self, forKey: .offsetSeconds)
        // `leadInSeconds` postdates the first shipped version of this
        // struct — settings persisted before it existed simply don't have
        // the key, so fall back to the original fixed 10s behavior.
        let leadInSeconds = try container.decodeIfPresent(Int.self, forKey: .leadInSeconds) ?? 10
        self.init(cycleSeconds: cycleSeconds, offsetSeconds: offsetSeconds, leadInSeconds: leadInSeconds)
    }

    /// The largest offset that keeps the pre/post ticks distinct from the
    /// main 0-mark and from each other.
    public static func maxOffsetSeconds(forCycleSeconds cycleSeconds: Int) -> Int {
        max(0, min(maxOffsetSecondsCeiling, cycleSeconds / 2 - 1))
    }

    /// Returns a copy with `cycleSeconds` updated, re-clamping `offsetSeconds`
    /// against the new cycle length if it no longer fits.
    public func settingCycleSeconds(_ newValue: Int) -> MetronomeSettings {
        MetronomeSettings(cycleSeconds: newValue, offsetSeconds: offsetSeconds, leadInSeconds: leadInSeconds)
    }

    /// Returns a copy with `offsetSeconds` updated (clamped to what the
    /// current cycle length allows).
    public func settingOffsetSeconds(_ newValue: Int) -> MetronomeSettings {
        MetronomeSettings(cycleSeconds: cycleSeconds, offsetSeconds: newValue, leadInSeconds: leadInSeconds)
    }

    /// Returns a copy with `leadInSeconds` updated.
    public func settingLeadInSeconds(_ newValue: Int) -> MetronomeSettings {
        MetronomeSettings(cycleSeconds: cycleSeconds, offsetSeconds: offsetSeconds, leadInSeconds: newValue)
    }

    /// True at second 0 of the cycle — the primary "you should be here" mark.
    public func isMarkSecond(_ secondsIntoCycle: Int) -> Bool {
        secondsIntoCycle == 0
    }

    /// True at the lead second before the mark (e.g. 41 for a 42s cycle with
    /// a 1s offset) — the "bip" warning that you're approaching the beep.
    /// Split from the post-mark case below because the caller treats them
    /// differently on the very first cycle (see `isPostMarkWarningSecond`).
    public func isPreMarkWarningSecond(_ secondsIntoCycle: Int) -> Bool {
        guard offsetSeconds > 0 else { return false }
        return secondsIntoCycle == cycleSeconds - offsetSeconds
    }

    /// True at the lag second after the mark (e.g. 1 for a 1s offset) — the
    /// "bip" warning that you've just passed the beep. Meaningless on the
    /// very first cycle before any mark has actually fired yet, so the
    /// caller only acts on this once it's seen at least one real mark.
    public func isPostMarkWarningSecond(_ secondsIntoCycle: Int) -> Bool {
        guard offsetSeconds > 0 else { return false }
        return secondsIntoCycle == offsetSeconds
    }

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
