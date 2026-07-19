import Foundation

/// The role a single step plays within a workout or countdown sequence.
public enum PhaseKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case prepare
    case warmup
    case work
    case rest
    case cooldown

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .prepare: "Get Ready"
        case .warmup: "Warm Up"
        case .work: "Work"
        case .rest: "Rest"
        case .cooldown: "Cool Down"
        }
    }

    /// Sensible default color per phase, used whenever no override is configured.
    public var defaultColor: CodableColor {
        switch self {
        case .prepare: CodableColor(red: 0.95, green: 0.72, blue: 0.20)
        case .warmup: CodableColor(red: 0.98, green: 0.58, blue: 0.24)
        case .work: CodableColor(red: 0.86, green: 0.19, blue: 0.30)
        case .rest: CodableColor(red: 0.16, green: 0.58, blue: 0.85)
        case .cooldown: CodableColor(red: 0.29, green: 0.68, blue: 0.55)
        }
    }
}
