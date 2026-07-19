import Foundation
import Testing
@testable import OpenStopTimerKit

struct WorkoutStoreTests {
    private func makeStore() -> WorkoutStore {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenStopTimerKitTests-\(UUID().uuidString)")
        return WorkoutStore(directory: directory)
    }

    @Test func savedWorkoutIsReturnedByLoadAll() throws {
        let store = makeStore()
        let workout = HIITWorkout(name: "Test Workout")
        try store.save(workout)

        let loaded = store.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.id == workout.id)
        #expect(loaded.first?.name == "Test Workout")
    }

    @Test func savingTwiceUpdatesRatherThanDuplicates() throws {
        let store = makeStore()
        var workout = HIITWorkout(name: "Original")
        try store.save(workout)

        workout.name = "Renamed"
        try store.save(workout)

        let loaded = store.loadAll()
        #expect(loaded.count == 1)
        #expect(loaded.first?.name == "Renamed")
    }

    @Test func deleteRemovesWorkout() throws {
        let store = makeStore()
        let workout = HIITWorkout(name: "Temp")
        try store.save(workout)
        #expect(store.loadAll().count == 1)

        store.delete(workout)
        #expect(store.loadAll().isEmpty)
    }

    @Test func loadAllOnEmptyDirectoryReturnsEmpty() {
        let store = makeStore()
        #expect(store.loadAll().isEmpty)
    }
}
