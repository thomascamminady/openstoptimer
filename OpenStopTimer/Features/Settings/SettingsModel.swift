import SwiftUI
import OpenStopTimerKit

/// Small pure-binding helpers so `SettingsView` can wire `ColorPicker`s and
/// `Picker`s directly at the dictionary-backed `AppearanceConfig` fields
/// without repeating the get/set boilerplate at every call site.
enum SettingsModel {
    static func colorBinding(_ config: Binding<AppearanceConfig>, for phase: PhaseKind) -> Binding<Color> {
        Binding(
            get: { config.wrappedValue.color(for: phase).color },
            set: { config.wrappedValue.setColor(CodableColor($0), for: phase) }
        )
    }

    static func soundBinding(_ config: Binding<AppearanceConfig>, for event: SoundEvent) -> Binding<SoundChoice> {
        Binding(
            get: { config.wrappedValue.sound(for: event) },
            set: { config.wrappedValue.setSound($0, for: event) }
        )
    }
}
