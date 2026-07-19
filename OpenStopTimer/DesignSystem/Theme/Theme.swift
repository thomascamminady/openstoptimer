import SwiftUI
import OpenStopTimerKit

/// Injects the resolved `AppearanceConfig` (global settings merged with any
/// per-workout override) into the environment so any view in the tree can
/// read colors/fonts/sounds without threading it through every initializer.
private struct AppearanceEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppearanceConfig.default
}

extension EnvironmentValues {
    var appearance: AppearanceConfig {
        get { self[AppearanceEnvironmentKey.self] }
        set { self[AppearanceEnvironmentKey.self] = newValue }
    }
}

extension View {
    func appearance(_ config: AppearanceConfig) -> some View {
        environment(\.appearance, config)
    }
}

extension PhaseKind {
    /// Convenience accessor honoring the environment's appearance config.
    func color(in appearance: AppearanceConfig) -> Color {
        appearance.color(for: self).color
    }
}
