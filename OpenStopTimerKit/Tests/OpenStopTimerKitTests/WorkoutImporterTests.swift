import Foundation
import Testing
@testable import OpenStopTimerKit

struct WorkoutImporterTests {
    @Test func importAssignsAFreshIdRatherThanReusingTheFilesId() throws {
        let original = HIITWorkout.exampleTabata()
        let file = WorkoutFile(workout: original)
        let data = try file.encode()

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkoutImporterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("shared.ostworkout")
        try data.write(to: fileURL)

        let imported = try WorkoutImporter.importWorkout(from: fileURL)

        // Importing must never reuse the file's original id — otherwise
        // re-importing an old backup or a re-shared file could silently
        // overwrite a newer local edit saved under that same id.
        #expect(imported.id != original.id)
        #expect(imported.name == original.name)
        #expect(imported.expandedSteps() == original.expandedSteps())
    }

    @Test func importOfInvalidDataThrowsInvalidFile() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("WorkoutImporterTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("not-a-workout.ostworkout")
        try Data("not json".utf8).write(to: fileURL)

        #expect(throws: WorkoutImporter.ImportError.self) {
            try WorkoutImporter.importWorkout(from: fileURL)
        }
    }
}
