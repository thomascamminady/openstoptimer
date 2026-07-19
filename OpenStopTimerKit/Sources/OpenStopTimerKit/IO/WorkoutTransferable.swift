import Foundation
import UniformTypeIdentifiers
import SwiftUI

public extension UTType {
    /// Custom file type for exported/imported OpenStopTimer workouts
    /// (`.ostworkout`, JSON). Declared here as the single source of truth;
    /// the app target's Info.plist exports/imports this same identifier so
    /// Files/Mail/AirDrop recognize it and offer "Open in OpenStopTimer."
    static let openStopTimerWorkout = UTType(
        exportedAs: "dev.camminady.openstoptimer.workout",
        conformingTo: .json
    )
}

/// Makes `HIITWorkout` shareable via `ShareLink` and importable via
/// `.fileImporter`/`.fileExporter`, wrapping it in the versioned `WorkoutFile`
/// envelope on the wire.
extension HIITWorkout: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(contentType: .openStopTimerWorkout) { workout in
            try WorkoutFile(workout: workout).encode()
        } importing: { data in
            try WorkoutFile.decode(data).workout
        }
        .suggestedFileName { workout in
            workout.name.isEmpty ? "Workout" : workout.name
        }
    }
}
