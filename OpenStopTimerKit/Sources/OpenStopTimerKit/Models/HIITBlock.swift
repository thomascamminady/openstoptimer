import Foundation

/// A compact, human-editable authoring unit for building a workout: either a single
/// explicit step, or a round-based group (e.g. "4 rounds of 3 exercises, resting
/// between each") that expands into many flat `WorkoutStep`s at play time.
public enum HIITBlock: Codable, Hashable, Sendable, Identifiable {
    case step(WorkoutStep)
    case roundGroup(RoundGroup)

    public struct RoundGroup: Codable, Hashable, Sendable, Identifiable {
        public var id: UUID
        public var name: String?
        public var exercises: [WorkoutStep]
        public var restBetweenExercises: WorkoutStep?
        public var rounds: Int
        public var restBetweenRounds: WorkoutStep?

        public init(
            id: UUID = UUID(),
            name: String? = nil,
            exercises: [WorkoutStep],
            restBetweenExercises: WorkoutStep? = nil,
            rounds: Int,
            restBetweenRounds: WorkoutStep? = nil
        ) {
            self.id = id
            self.name = name
            self.exercises = exercises
            self.restBetweenExercises = restBetweenExercises
            self.rounds = max(1, rounds)
            self.restBetweenRounds = restBetweenRounds
        }
    }

    public var id: UUID {
        switch self {
        case .step(let step): step.id
        case .roundGroup(let group): group.id
        }
    }

    /// Flattens this block into the ordered list of steps that will actually be
    /// played. Pure function of the block's contents — no dependency on the clock,
    /// which is what makes it trivial to unit test.
    public func expand() -> [WorkoutStep] {
        switch self {
        case .step(let step):
            return [step]

        case .roundGroup(let group):
            guard !group.exercises.isEmpty else { return [] }
            var steps: [WorkoutStep] = []
            for round in 0..<group.rounds {
                for (index, exercise) in group.exercises.enumerated() {
                    steps.append(exercise)
                    let isLastExerciseInRound = index == group.exercises.count - 1
                    if !isLastExerciseInRound, let rest = group.restBetweenExercises {
                        steps.append(rest)
                    }
                }
                let isLastRound = round == group.rounds - 1
                if !isLastRound, let rest = group.restBetweenRounds {
                    steps.append(rest)
                }
            }
            return steps
        }
    }
}

public extension Array where Element == HIITBlock {
    /// Flattens an ordered list of blocks into the full playable step sequence.
    func expandedSteps() -> [WorkoutStep] {
        flatMap { $0.expand() }
    }
}
