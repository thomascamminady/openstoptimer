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
