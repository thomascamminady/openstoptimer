import Foundation
import Observation
import OpenStopTimerKit

@MainActor
@Observable
final class HIITEditorModel {
    var workout: HIITWorkout
    private let store: WorkoutStore
    private let onSave: () -> Void

    init(workout: HIITWorkout, store: WorkoutStore, onSave: @escaping () -> Void) {
        self.workout = workout
        self.store = store
        self.onSave = onSave
    }

    var canSave: Bool {
        // Check expanded steps, not just blocks.isEmpty: a round group whose
        // exercises were all deleted still counts as a "block" but produces
        // zero playable steps.
        !workout.expandedSteps().isEmpty && !workout.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func addStep(kind: PhaseKind, duration: TimeInterval) {
        workout.blocks.append(.step(WorkoutStep(name: kind.displayName, kind: kind, duration: duration)))
    }

    func addWarmup() {
        workout.blocks.append(.step(WorkoutStep(name: "Warm Up", kind: .warmup, duration: 60)))
    }

    func addCooldown() {
        workout.blocks.append(.step(WorkoutStep(name: "Cool Down", kind: .cooldown, duration: 60)))
    }

    /// Adds a new interval block pre-filled with a sensible "10 rounds of
    /// 30s work / 30s rest" starting point, and returns its id so the caller
    /// can immediately open it for editing — this is the fast path for
    /// "10x work/rest" and, after bumping Sets, "3x10" style workouts.
    @discardableResult
    func addRoundGroup() -> HIITBlock.ID {
        let group = HIITBlock.RoundGroup(
            exercises: [WorkoutStep(name: "Work", kind: .work, duration: 30)],
            rounds: 10,
            restBetweenRounds: WorkoutStep(name: "Rest", kind: .rest, duration: 30)
        )
        let block = HIITBlock.roundGroup(group)
        workout.blocks.append(block)
        return block.id
    }

    func removeBlocks(at offsets: IndexSet) {
        workout.blocks.remove(atOffsets: offsets)
    }

    func moveBlocks(from source: IndexSet, to destination: Int) {
        workout.blocks.move(fromOffsets: source, toOffset: destination)
    }

    func save() {
        try? store.save(workout)
        onSave()
    }
}
