import SwiftUI
import OpenStopTimerKit

/// Binding helpers for editing a single workout's sparse `AppearanceOverride`
/// (mirrors `SettingsModel`, which does the same for the global config).
/// Each getter falls back to the live global config for any field this
/// workout hasn't touched; each setter writes only that one field, so
/// untouched fields keep tracking whatever Settings says.
enum WorkoutAppearanceModel {
    static func colorBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig, for phase: PhaseKind) -> Binding<Color> {
        Binding(
            get: { (override.wrappedValue.phaseColors?[phase.rawValue] ?? global.color(for: phase)).color },
            set: { newValue in
                var colors = override.wrappedValue.phaseColors ?? [:]
                colors[phase.rawValue] = CodableColor(newValue)
                override.wrappedValue.phaseColors = colors
            }
        )
    }

    static func soundBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig, for event: SoundEvent) -> Binding<SoundChoice> {
        Binding(
            get: { override.wrappedValue.sounds?[event.rawValue] ?? global.sound(for: event) },
            set: { newValue in
                var sounds = override.wrappedValue.sounds ?? [:]
                sounds[event.rawValue] = newValue
                override.wrappedValue.sounds = sounds
            }
        )
    }

    static func fontScaleBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig) -> Binding<Double> {
        Binding(
            get: { override.wrappedValue.fontScale ?? global.fontScale },
            set: { override.wrappedValue.fontScale = $0 }
        )
    }

    static func currentNextRatioBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig) -> Binding<Double> {
        Binding(
            get: { override.wrappedValue.currentNextRatio ?? global.currentNextRatio },
            set: { override.wrappedValue.currentNextRatio = $0 }
        )
    }

    static func soundsEnabledBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig) -> Binding<Bool> {
        Binding(
            get: { override.wrappedValue.soundsEnabled ?? global.soundsEnabled },
            set: { override.wrappedValue.soundsEnabled = $0 }
        )
    }

    static func hapticsEnabledBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig) -> Binding<Bool> {
        Binding(
            get: { override.wrappedValue.hapticsEnabled ?? global.hapticsEnabled },
            set: { override.wrappedValue.hapticsEnabled = $0 }
        )
    }

    static func tickLeadSecondsBinding(_ override: Binding<AppearanceOverride>, global: AppearanceConfig) -> Binding<Int> {
        Binding(
            get: { override.wrappedValue.tickLeadSeconds ?? global.tickLeadSeconds },
            set: { override.wrappedValue.tickLeadSeconds = $0 }
        )
    }
}
