import Foundation

/// An all-optional mirror of `AppearanceConfig` that a single workout can carry.
/// Only the fields a user actually touched are present, which keeps exported
/// workout JSON small; `resolved(against:)` merges it over a base config.
public struct AppearanceOverride: Codable, Hashable, Sendable {
    public var phaseColors: [String: CodableColor]?
    public var backgroundColor: CodableColor?
    public var fontScale: Double?
    public var currentNextRatio: Double?
    public var sounds: [String: SoundChoice]?
    public var tickLeadSeconds: Int?
    public var soundsEnabled: Bool?
    public var hapticsEnabled: Bool?

    public init(
        phaseColors: [String: CodableColor]? = nil,
        backgroundColor: CodableColor? = nil,
        fontScale: Double? = nil,
        currentNextRatio: Double? = nil,
        sounds: [String: SoundChoice]? = nil,
        tickLeadSeconds: Int? = nil,
        soundsEnabled: Bool? = nil,
        hapticsEnabled: Bool? = nil
    ) {
        self.phaseColors = phaseColors
        self.backgroundColor = backgroundColor
        self.fontScale = fontScale
        self.currentNextRatio = currentNextRatio
        self.sounds = sounds
        self.tickLeadSeconds = tickLeadSeconds
        self.soundsEnabled = soundsEnabled
        self.hapticsEnabled = hapticsEnabled
    }

    /// Merges this override on top of `base`, keeping every field from `base`
    /// that this override doesn't explicitly set.
    public func resolved(against base: AppearanceConfig) -> AppearanceConfig {
        var result = base
        if let phaseColors {
            for (key, value) in phaseColors { result.phaseColors[key] = value }
        }
        if let backgroundColor { result.backgroundColor = backgroundColor }
        if let fontScale { result.fontScale = fontScale }
        if let currentNextRatio { result.currentNextRatio = currentNextRatio }
        if let sounds {
            for (key, value) in sounds { result.sounds[key] = value }
        }
        if let tickLeadSeconds { result.tickLeadSeconds = tickLeadSeconds }
        if let soundsEnabled { result.soundsEnabled = soundsEnabled }
        if let hapticsEnabled { result.hapticsEnabled = hapticsEnabled }
        return result
    }
}
