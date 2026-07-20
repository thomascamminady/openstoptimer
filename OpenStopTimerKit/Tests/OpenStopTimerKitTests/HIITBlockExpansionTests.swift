import Testing
@testable import OpenStopTimerKit

struct HIITBlockExpansionTests {
    @Test func singleStepExpandsToItself() {
        let step = WorkoutStep(name: "Rest", kind: .rest, duration: 15)
        #expect(HIITBlock.step(step).expand() == [step])
    }

    @Test func roundGroupWithoutRestsRepeatsExercisesInOrder() {
        let exercises = [
            WorkoutStep(name: "Push-ups", kind: .work, duration: 30),
            WorkoutStep(name: "Squats", kind: .work, duration: 30),
        ]
        let group = HIITBlock.RoundGroup(exercises: exercises, rounds: 3)
        let expanded = HIITBlock.roundGroup(group).expand()

        #expect(expanded.count == 6)
        #expect(expanded.map(\.name) == ["Push-ups", "Squats", "Push-ups", "Squats", "Push-ups", "Squats"])
    }

    @Test func roundGroupInsertsRestBetweenExercisesButNotAfterLast() {
        let exercises = [
            WorkoutStep(name: "A", kind: .work, duration: 10),
            WorkoutStep(name: "B", kind: .work, duration: 10),
        ]
        let rest = WorkoutStep(name: "Rest", kind: .rest, duration: 5)
        let group = HIITBlock.RoundGroup(exercises: exercises, restBetweenExercises: rest, rounds: 1)
        let expanded = HIITBlock.roundGroup(group).expand()

        // A, rest, B  -- no trailing rest after the last exercise in the round.
        #expect(expanded.map(\.name) == ["A", "Rest", "B"])
    }

    @Test func roundGroupInsertsRestBetweenRoundsButNotAfterLast() {
        let exercises = [WorkoutStep(name: "A", kind: .work, duration: 10)]
        let roundRest = WorkoutStep(name: "Round Rest", kind: .rest, duration: 20)
        let group = HIITBlock.RoundGroup(exercises: exercises, rounds: 3, restBetweenRounds: roundRest)
        let expanded = HIITBlock.roundGroup(group).expand()

        // A, rest, A, rest, A -- no trailing rest after the final round.
        #expect(expanded.map(\.name) == ["A", "Round Rest", "A", "Round Rest", "A"])
    }

    @Test func emptyExercisesExpandsToNothing() {
        let group = HIITBlock.RoundGroup(exercises: [], rounds: 5)
        #expect(HIITBlock.roundGroup(group).expand().isEmpty)
    }

    @Test func roundsBelowOneAreClampedToOne() {
        let exercises = [WorkoutStep(name: "A", kind: .work, duration: 10)]
        let group = HIITBlock.RoundGroup(exercises: exercises, rounds: 0)
        #expect(HIITBlock.roundGroup(group).expand().count == 1)
    }

    @Test func setsRepeatTheWholeRoundBlockWithRestBetweenSetsButNotAfterLast() {
        // "3x10" — 3 sets of 10 rounds of 30s work.
        let exercises = [WorkoutStep(name: "Work", kind: .work, duration: 30)]
        let roundRest = WorkoutStep(name: "Rest", kind: .rest, duration: 30)
        let setRest = WorkoutStep(name: "Set Rest", kind: .rest, duration: 60)
        let group = HIITBlock.RoundGroup(
            exercises: exercises,
            rounds: 10,
            restBetweenRounds: roundRest,
            sets: 3,
            restBetweenSets: setRest
        )
        let expanded = HIITBlock.roundGroup(group).expand()

        // Each set: Work,Rest x10 minus the trailing rest = 19 steps. 3 sets
        // + 2 "Set Rest" connectors between them (not after the last set).
        #expect(expanded.count == 19 * 3 + 2)
        #expect(expanded.filter { $0.name == "Set Rest" }.count == 2)
        #expect(expanded.last?.name == "Work")
    }

    @Test func setsBelowOneAreClampedToOne() {
        let exercises = [WorkoutStep(name: "A", kind: .work, duration: 10)]
        let group = HIITBlock.RoundGroup(exercises: exercises, rounds: 1, sets: 0)
        #expect(HIITBlock.roundGroup(group).expand().count == 1)
    }

    @Test func expandedStepsCarryRoundAndSetProgress() {
        let exercises = [WorkoutStep(name: "Work", kind: .work, duration: 20)]
        let group = HIITBlock.RoundGroup(exercises: exercises, rounds: 2, sets: 2)
        let expanded = HIITBlock.roundGroup(group).expand()

        #expect(expanded.count == 4) // 2 sets x 2 rounds, no rests configured
        #expect(expanded[0].roundProgress == .init(round: 1, totalRounds: 2, set: 1, totalSets: 2))
        #expect(expanded[1].roundProgress == .init(round: 2, totalRounds: 2, set: 1, totalSets: 2))
        #expect(expanded[2].roundProgress == .init(round: 1, totalRounds: 2, set: 2, totalSets: 2))
        #expect(expanded[3].roundProgress == .init(round: 2, totalRounds: 2, set: 2, totalSets: 2))
    }

    @Test func singleStepsHaveNoRoundProgress() {
        let step = WorkoutStep(name: "Warm Up", kind: .warmup, duration: 60)
        #expect(HIITBlock.step(step).expand().first?.roundProgress == nil)
    }

    @Test func expandedStepsGetFreshIdsPerRepetition() {
        let exercises = [WorkoutStep(name: "Work", kind: .work, duration: 20)]
        let group = HIITBlock.RoundGroup(exercises: exercises, rounds: 3)
        let expanded = HIITBlock.roundGroup(group).expand()

        #expect(Set(expanded.map(\.id)).count == 3, "each repetition must get a unique id")
    }

    @Test func arrayOfBlocksFlattensInOrder() {
        let prepare = WorkoutStep(name: "Prepare", kind: .prepare, duration: 10)
        let group = HIITBlock.RoundGroup(
            exercises: [WorkoutStep(name: "Work", kind: .work, duration: 20)],
            rounds: 2,
            restBetweenRounds: WorkoutStep(name: "Rest", kind: .rest, duration: 10)
        )
        let cooldown = WorkoutStep(name: "Cool Down", kind: .cooldown, duration: 30)
        let blocks: [HIITBlock] = [.step(prepare), .roundGroup(group), .step(cooldown)]

        let expanded = blocks.expandedSteps()
        #expect(expanded.map(\.name) == ["Prepare", "Work", "Rest", "Work", "Cool Down"])
    }
}
