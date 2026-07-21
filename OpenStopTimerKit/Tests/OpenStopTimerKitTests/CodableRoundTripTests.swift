import Foundation
import Testing
@testable import OpenStopTimerKit

struct CodableRoundTripTests {
    @Test func hiitWorkoutRoundTripsThroughWorkoutFile() throws {
        let workout = HIITWorkout.exampleTabata()
        let file = WorkoutFile(workout: workout)
        let data = try file.encode()
        let decoded = try WorkoutFile.decode(data)

        #expect(decoded.workout.id == workout.id)
        #expect(decoded.workout.name == workout.name)
        // Compare the authored blocks, not `expandedSteps()` — expansion
        // mints a fresh id per generated step by design (see HIITBlock),
        // so two separate calls are never `==` even for the same workout.
        #expect(decoded.workout.blocks == workout.blocks)
        #expect(decoded.schemaVersion == WorkoutFile.currentSchemaVersion)
    }

    @Test func decodingRejectsNewerSchemaVersion() throws {
        let workout = HIITWorkout(name: "Future", blocks: [])
        var file = WorkoutFile(workout: workout)
        file.schemaVersion = WorkoutFile.currentSchemaVersion + 1
        let data = try file.encode() // uses WorkoutFile's own .iso8601 date strategy

        #expect(throws: WorkoutFile.DecodingError.self) {
            try WorkoutFile.decode(data)
        }
    }

    @Test func appearanceOverrideRoundTripsWithOnlyTouchedFieldsPresent() throws {
        var override = AppearanceOverride()
        override.fontScale = 1.5
        let data = try JSONEncoder().encode(override)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("fontScale"))
        #expect(!json.contains("hapticsEnabled"))

        let decoded = try JSONDecoder().decode(AppearanceOverride.self, from: data)
        #expect(decoded.fontScale == 1.5)
        #expect(decoded.hapticsEnabled == nil)
    }

    /// `groupName` postdates the first shipped version of `RoundProgress` —
    /// a workout saved/exported before it existed simply won't have the key,
    /// and since it's an `Optional`, the synthesized decoder should default
    /// it to `nil` rather than fail the whole decode.
    @Test func decodingOlderRoundProgressWithoutGroupNameDefaultsToNil() throws {
        let legacyJSON = Data(#"{"round":1,"totalRounds":10,"set":1,"totalSets":1}"#.utf8)
        let decoded = try JSONDecoder().decode(WorkoutStep.RoundProgress.self, from: legacyJSON)
        #expect(decoded.round == 1)
        #expect(decoded.totalRounds == 10)
        #expect(decoded.groupName == nil)
    }

    @Test func lapRecordRoundTrips() throws {
        let lap = LapRecord(index: 1, lapTime: 12.34, cumulativeTime: 12.34)
        let data = try JSONEncoder().encode(lap)
        let decoded = try JSONDecoder().decode(LapRecord.self, from: data)
        #expect(decoded == lap)
    }
}
