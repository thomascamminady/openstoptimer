import Foundation

/// Decodes a `HIITWorkout` from an on-disk `.ostworkout` file, handling the
/// security-scoped access required for URLs handed to us by `.fileImporter`
/// or `.onOpenURL` (Files app / AirDrop).
public enum WorkoutImporter {
    public enum ImportError: Error, LocalizedError {
        case accessDenied
        case invalidFile(underlying: Error)

        public var errorDescription: String? {
            switch self {
            case .accessDenied:
                "OpenStopTimer couldn't access that file."
            case .invalidFile(let underlying):
                "That doesn't look like a valid workout file: \(underlying.localizedDescription)"
            }
        }
    }

    public static func importWorkout(from url: URL) throws -> HIITWorkout {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { url.stopAccessingSecurityScopedResource() } }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw ImportError.accessDenied
        }

        var workout: HIITWorkout
        do {
            workout = try WorkoutFile.decode(data).workout
        } catch {
            throw ImportError.invalidFile(underlying: error)
        }

        // Always import as a new library entry, even if the file's id
        // collides with one already saved locally — otherwise importing an
        // old backup or a re-shared file could silently overwrite newer
        // local edits under the same id.
        workout.id = UUID()
        workout.createdAt = .now
        workout.updatedAt = .now
        return workout
    }
}
