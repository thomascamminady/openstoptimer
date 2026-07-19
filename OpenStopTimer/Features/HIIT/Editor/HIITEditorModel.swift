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

    func addRoundGroup() {
        let group = HIITBlock.RoundGroup(
            exercises: [WorkoutStep(name: "Work", kind: .work, duration: 30)],
            rounds: 3,
            restBetweenRounds: WorkoutStep(name: "Rest", kind: .rest, duration: 15)
        )
        workout.blocks.append(.roundGroup(group))
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
