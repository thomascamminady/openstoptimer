import Foundation

/// A bundled sound a user can pick for a given `SoundEvent`. `.none` plays nothing.
public enum SoundChoice: String, Codable, CaseIterable, Sendable, Identifiable {
    case none
    case beepShort
    case beepLong
    case beepDouble
    case chime
    case bell
    case whistle

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none: "None"
        case .beepShort: "Short Beep"
        case .beepLong: "Long Beep"
        case .beepDouble: "Double Beep"
        case .chime: "Chime"
        case .bell: "Bell"
        case .whistle: "Whistle"
        }
    }

    /// Base filename (without extension) of the bundled audio asset, or `nil` for `.none`.
    public var resourceName: String? {
        self == .none ? nil : rawValue
    }
}
