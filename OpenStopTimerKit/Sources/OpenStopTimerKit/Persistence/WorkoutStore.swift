import Foundation

/// On-device library of saved HIIT workouts: one `.ostworkout` JSON file per
/// workout in a directory. The stored format is exactly the export format
/// (`WorkoutFile`), so there's no separate internal schema to keep in sync.
public final class WorkoutStore {
    public static let fileExtension = "ostworkout"

    private let directory: URL
    private let fileManager: FileManager

    /// - Parameter directory: injected for testability; defaults to
    ///   `Application Support/Workouts` (not Documents — that's for files the
    ///   user manages directly, whereas this is the app's own internal library).
    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let directory {
            self.directory = directory
        } else {
            let support = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            self.directory = support.appendingPathComponent("Workouts", isDirectory: true)
        }
        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    private func url(for workoutID: UUID) -> URL {
        directory.appendingPathComponent(workoutID.uuidString).appendingPathExtension(Self.fileExtension)
    }

    public func loadAll() -> [HIITWorkout] {
        guard let urls = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
            return []
        }
        return urls
            .filter { $0.pathExtension == Self.fileExtension }
            .compactMap { url -> HIITWorkout? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? WorkoutFile.decode(data).workout
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    @discardableResult
    public func save(_ workout: HIITWorkout) throws -> URL {
        var workout = workout
        workout.updatedAt = .now
        let file = WorkoutFile(workout: workout)
        let data = try file.encode()
        let destination = url(for: workout.id)
        try data.write(to: destination, options: .atomic)
        return destination
    }

    public func delete(_ workout: HIITWorkout) {
        try? fileManager.removeItem(at: url(for: workout.id))
    }

    public func delete(id: UUID) {
        try? fileManager.removeItem(at: url(for: id))
    }

    /// Removes every saved workout. Used to give UI tests a clean slate.
    public func deleteAll() {
        for workout in loadAll() {
            delete(workout)
        }
    }
}
