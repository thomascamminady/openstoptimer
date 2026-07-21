import Foundation

/// A compact, human-editable authoring unit for building a workout: either a single
/// explicit step, or a round-based group (e.g. "3 sets of 10 rounds of work/rest")
/// that expands into many flat `WorkoutStep`s at play time.
public enum HIITBlock: Codable, Hashable, Sendable, Identifiable {
    case step(WorkoutStep)
    case roundGroup(RoundGroup)

    /// A nested-loop interval block: `sets` repetitions of `rounds` repetitions
    /// of `exercises`. A simple "10x work/rest" is `sets == 1`; "3x10" (3 sets
    /// of 10 rounds) is `sets == 3, rounds == 10`.
    public struct RoundGroup: Codable, Hashable, Sendable, Identifiable {
        public var id: UUID
        public var name: String?
        public var exercises: [WorkoutStep]
        public var restBetweenExercises: WorkoutStep?
        public var rounds: Int
        public var restBetweenRounds: WorkoutStep?
        public var sets: Int
        public var restBetweenSets: WorkoutStep?

        public init(
            id: UUID = UUID(),
            name: String? = nil,
            exercises: [WorkoutStep],
            restBetweenExercises: WorkoutStep? = nil,
            rounds: Int,
            restBetweenRounds: WorkoutStep? = nil,
            sets: Int = 1,
            restBetweenSets: WorkoutStep? = nil
        ) {
            self.id = id
            self.name = name
            self.exercises = exercises
            self.restBetweenExercises = restBetweenExercises
            self.rounds = max(1, rounds)
            self.restBetweenRounds = restBetweenRounds
            self.sets = max(1, sets)
            self.restBetweenSets = restBetweenSets
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
    /// which is what makes it trivial to unit test. Every generated step gets a
    /// fresh id (the same authored exercise is copied once per round/set) and,
    /// for round-group steps, `roundProgress` so the player can show "3/10".
    public func expand() -> [WorkoutStep] {
        switch self {
        case .step(let step):
            return [step]

        case .roundGroup(let group):
            guard !group.exercises.isEmpty else { return [] }
            var steps: [WorkoutStep] = []
            for set in 0..<group.sets {
                for round in 0..<group.rounds {
                    let progress = WorkoutStep.RoundProgress(
                        round: round + 1,
                        totalRounds: group.rounds,
                        set: set + 1,
                        totalSets: group.sets,
                        groupName: group.name
                    )
                    for (index, exercise) in group.exercises.enumerated() {
                        steps.append(exercise.copyForPlayback(withProgress: progress))
                        let isLastExerciseInRound = index == group.exercises.count - 1
                        if !isLastExerciseInRound, let rest = group.restBetweenExercises {
                            steps.append(rest.copyForPlayback(withProgress: progress))
                        }
                    }
                    let isLastRound = round == group.rounds - 1
                    if !isLastRound, let rest = group.restBetweenRounds {
                        steps.append(rest.copyForPlayback(withProgress: progress))
                    }
                }
                let isLastSet = set == group.sets - 1
                if !isLastSet, let rest = group.restBetweenSets {
                    steps.append(rest.copyForPlayback(withProgress: nil))
                }
            }
            return steps
        }
    }
}

private extension WorkoutStep {
    func copyForPlayback(withProgress progress: RoundProgress?) -> WorkoutStep {
        var copy = self
        copy.id = UUID()
        copy.roundProgress = progress
        return copy
    }
}

public extension Array where Element == HIITBlock {
    /// Flattens an ordered list of blocks into the full playable step sequence.
    func expandedSteps() -> [WorkoutStep] {
        flatMap { $0.expand() }
    }
}
