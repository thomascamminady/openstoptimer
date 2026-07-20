import Foundation

/// A single, flat, playable unit of time. This is the runtime representation the
/// timer engine consumes — `HIITBlock` expands down to a sequence of these.
public struct WorkoutStep: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: PhaseKind
    public var duration: TimeInterval
    public var colorOverride: CodableColor?
    /// Set only for steps generated from within a `HIITBlock.RoundGroup` —
    /// lets the player show "Round 3/10" (and "Set 2/3" for nested loops).
    public var roundProgress: RoundProgress?

    public struct RoundProgress: Codable, Hashable, Sendable {
        public var round: Int
        public var totalRounds: Int
        public var set: Int
        public var totalSets: Int

        public init(round: Int, totalRounds: Int, set: Int, totalSets: Int) {
            self.round = round
            self.totalRounds = totalRounds
            self.set = set
            self.totalSets = totalSets
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        kind: PhaseKind,
        duration: TimeInterval,
        colorOverride: CodableColor? = nil,
        roundProgress: RoundProgress? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.duration = duration
        self.colorOverride = colorOverride
        self.roundProgress = roundProgress
    }

    public var color: CodableColor {
        colorOverride ?? kind.defaultColor
    }
}
