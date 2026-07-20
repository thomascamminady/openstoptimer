import Foundation
import Observation
import OpenStopTimerKit

@MainActor
@Observable
final class HIITLibraryModel {
    private(set) var workouts: [HIITWorkout] = []
    private let store: WorkoutStore

    init(store: WorkoutStore) {
        self.store = store
        reload()
    }

    func reload() {
        workouts = store.loadAll()
    }

    func delete(_ workout: HIITWorkout) {
        store.delete(workout)
        reload()
    }

    @discardableResult
    func duplicate(_ workout: HIITWorkout) -> HIITWorkout {
        var copy = workout
        copy.id = UUID()
        copy.name = "\(workout.name) Copy"
        copy.createdAt = .now
        copy.updatedAt = .now
        try? store.save(copy)
        reload()
        return copy
    }

    @discardableResult
    func importWorkout(from url: URL) throws -> HIITWorkout {
        let workout = try WorkoutImporter.importWorkout(from: url)
        try store.save(workout)
        reload()
        return workout
    }
}
