import Foundation

/// A single, flat, playable unit of time. This is the runtime representation the
/// timer engine consumes — `HIITBlock` expands down to a sequence of these.
public struct WorkoutStep: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: PhaseKind
    public var duration: TimeInterval
    /// Set only for steps generated from within a `HIITBlock.RoundGroup` —
    /// lets the player show "Round 3/10" (and "Set 2/3" for nested loops).
    public var roundProgress: RoundProgress?

    public struct RoundProgress: Codable, Hashable, Sendable {
        public var round: Int
        public var totalRounds: Int
        public var set: Int
        public var totalSets: Int
        /// The authoring `RoundGroup`'s own custom name (e.g. "Sprint
        /// Intervals"), if the user gave it one — otherwise this metadata
        /// would be the only trace of a round group ever existing, since
        /// `expand()` discards everything about the group except this.
        public var groupName: String?

        public init(round: Int, totalRounds: Int, set: Int, totalSets: Int, groupName: String? = nil) {
            self.round = round
            self.totalRounds = totalRounds
            self.set = set
            self.totalSets = totalSets
            self.groupName = groupName
        }
    }

    public init(
        id: UUID = UUID(),
        name: String,
        kind: PhaseKind,
        duration: TimeInterval,
        roundProgress: RoundProgress? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.duration = duration
        self.roundProgress = roundProgress
    }
}
