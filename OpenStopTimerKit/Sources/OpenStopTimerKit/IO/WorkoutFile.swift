import Foundation

/// The versioned envelope both the on-device workout store and file
/// export/import use. `schemaVersion` is bumped on breaking model changes;
/// `migrate` is the seam for translating older files forward.
public struct WorkoutFile: Codable, Equatable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var exportedAt: Date
    public var workout: HIITWorkout

    public init(workout: HIITWorkout, exportedAt: Date = .now) {
        self.schemaVersion = Self.currentSchemaVersion
        self.exportedAt = exportedAt
        self.workout = workout
    }

    public enum DecodingError: Error, LocalizedError {
        case unsupportedSchemaVersion(Int)

        public var errorDescription: String? {
            switch self {
            case .unsupportedSchemaVersion(let version):
                "This workout file uses a newer format (v\(version)) than this version of OpenStopTimer supports."
            }
        }
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    public func encode() throws -> Data {
        try Self.encoder.encode(self)
    }

    /// Decodes a `WorkoutFile`, running any schema migrations needed to bring
    /// an older file up to `currentSchemaVersion`. Throws if the file is from
    /// a *newer* schema version than this build understands.
    public static func decode(_ data: Data) throws -> WorkoutFile {
        var file = try decoder.decode(WorkoutFile.self, from: data)
        guard file.schemaVersion <= currentSchemaVersion else {
            throw DecodingError.unsupportedSchemaVersion(file.schemaVersion)
        }
        // Migration stub: as of schema v1 there is nothing to migrate. Future
        // breaking changes add `if file.schemaVersion < N { ...; file.schemaVersion = N }`
        // steps here, one per version bump.
        file.schemaVersion = currentSchemaVersion
        return file
    }
}
