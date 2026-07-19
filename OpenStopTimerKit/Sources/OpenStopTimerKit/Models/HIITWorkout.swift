import Foundation

/// A saved, named HIIT workout: an ordered list of blocks plus optional
/// appearance overrides. This is both the in-app library representation and
/// (wrapped in `WorkoutFile`) the exported/imported file representation.
public struct HIITWorkout: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var blocks: [HIITBlock]
    public var appearanceOverride: AppearanceOverride?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        blocks: [HIITBlock] = [],
        appearanceOverride: AppearanceOverride? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.blocks = blocks
        self.appearanceOverride = appearanceOverride
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// The full flat step sequence this workout plays, in order.
    public func expandedSteps() -> [WorkoutStep] {
        blocks.expandedSteps()
    }

    public var totalDuration: TimeInterval {
        expandedSteps().reduce(0) { $0 + $1.duration }
    }
}

public extension HIITWorkout {
    /// A small example workout so the library and previews aren't empty on first launch.
    static func exampleTabata() -> HIITWorkout {
        HIITWorkout(
            name: "Tabata",
            blocks: [
                .step(WorkoutStep(name: "Get Ready", kind: .prepare, duration: 10)),
                .roundGroup(
                    HIITBlock.RoundGroup(
                        name: "Tabata Rounds",
                        exercises: [WorkoutStep(name: "Work", kind: .work, duration: 20)],
                        rounds: 8,
                        restBetweenRounds: WorkoutStep(name: "Rest", kind: .rest, duration: 10)
                    )
                ),
                .step(WorkoutStep(name: "Cool Down", kind: .cooldown, duration: 30))
            ]
        )
    }
}
