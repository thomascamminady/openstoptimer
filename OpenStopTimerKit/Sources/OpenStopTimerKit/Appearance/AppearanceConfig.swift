import Foundation

/// Full appearance/behavior configuration shared by the HIIT player and the lap
/// stopwatch: colors, text scale, current/next layout ratio, and sound/haptics
/// choices. Every field has a default, so the app is fully usable unconfigured.
public struct AppearanceConfig: Codable, Hashable, Sendable {
    /// Keyed by `PhaseKind.rawValue`.
    public var phaseColors: [String: CodableColor]
    public var backgroundColor: CodableColor
    /// Multiplier applied on top of the Dynamic-Type-aware base size for the big
    /// timer display.
    public var fontScale: Double
    /// How much of the layout the "current" step occupies vs. the "next" preview,
    /// from 0 (all next) to 1 (all current).
    public var currentNextRatio: Double
    /// Keyed by `SoundEvent.rawValue`.
    public var sounds: [String: SoundChoice]
    /// How many seconds before a phase ends the countdown-tick sound starts playing.
    public var tickLeadSeconds: Int
    public var soundsEnabled: Bool
    public var hapticsEnabled: Bool

    public init(
        phaseColors: [String: CodableColor] = [:],
        backgroundColor: CodableColor = CodableColor(red: 0.07, green: 0.07, blue: 0.09),
        fontScale: Double = 1.0,
        currentNextRatio: Double = 0.75,
        sounds: [String: SoundChoice] = [:],
        tickLeadSeconds: Int = 3,
        soundsEnabled: Bool = true,
        hapticsEnabled: Bool = true
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

    public static let `default` = AppearanceConfig()

    public func color(for phase: PhaseKind) -> CodableColor {
        phaseColors[phase.rawValue] ?? phase.defaultColor
    }

    public mutating func setColor(_ color: CodableColor, for phase: PhaseKind) {
        phaseColors[phase.rawValue] = color
    }

    public func sound(for event: SoundEvent) -> SoundChoice {
        guard soundsEnabled else { return .none }
        return sounds[event.rawValue] ?? event.defaultSound
    }

    public mutating func setSound(_ choice: SoundChoice, for event: SoundEvent) {
        sounds[event.rawValue] = choice
    }
}
