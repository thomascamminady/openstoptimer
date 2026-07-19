import Foundation

/// A single, flat, playable unit of time. This is the runtime representation the
/// timer engine consumes — `HIITBlock` expands down to a sequence of these.
public struct WorkoutStep: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var kind: PhaseKind
    public var duration: TimeInterval
    public var colorOverride: CodableColor?

    public init(
        id: UUID = UUID(),
        name: String,
        kind: PhaseKind,
        duration: TimeInterval,
        colorOverride: CodableColor? = nil
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.duration = duration
        self.colorOverride = colorOverride
    }

    public var color: CodableColor {
        colorOverride ?? kind.defaultColor
    }
}
