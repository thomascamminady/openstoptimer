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
        workout.blocks.insert(.step(WorkoutStep(name: kind.displayName, kind: kind, duration: duration)), at: middleSectionEnd)
    }

    /// Always inserted right after any existing Warm Up blocks, regardless
    /// of what's already been added — otherwise adding a Warm Up *after* an
    /// interval left it stuck at the end of the workout instead of the start.
    func addWarmup() {
        workout.blocks.insert(.step(WorkoutStep(name: "Warm Up", kind: .warmup, duration: 60)), at: middleSectionStart)
    }

    /// Always inserted right before any existing Cool Down blocks, for the
    /// same reason: adding one shouldn't depend on tap order.
    func addCooldown() {
        workout.blocks.insert(.step(WorkoutStep(name: "Cool Down", kind: .cooldown, duration: 60)), at: middleSectionEnd)
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
        workout.blocks.insert(block, at: middleSectionEnd)
        return block.id
    }

    /// Index just past the leading run of Warm Up blocks (0 if there aren't
    /// any) — where a newly-added Warm Up, or the start of the "middle"
    /// section, belongs.
    private var middleSectionStart: Int {
        var index = 0
        while index < workout.blocks.count, Self.isWarmup(workout.blocks[index]) {
            index += 1
        }
        return index
    }

    /// Index just before the trailing run of Cool Down blocks (`blocks.count`
    /// if there aren't any) — where a newly-added interval/step, or a
    /// newly-added Cool Down, belongs.
    private var middleSectionEnd: Int {
        var index = workout.blocks.count
        while index > 0, Self.isCooldown(workout.blocks[index - 1]) {
            index -= 1
        }
        return index
    }

    private static func isWarmup(_ block: HIITBlock) -> Bool {
        if case .step(let step) = block { return step.kind == .warmup }
        return false
    }

    private static func isCooldown(_ block: HIITBlock) -> Bool {
        if case .step(let step) = block { return step.kind == .cooldown }
        return false
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
