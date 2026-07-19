import Foundation
import Observation
import OpenStopTimerKit

/// App-wide state: the global (default) appearance configuration used by
/// HIIT and Lap Stopwatch whenever a workout doesn't override it, plus the
/// on-device workout library. The two "simple" modes intentionally don't
/// read this — they use fixed, sensible defaults and need zero setup.
@MainActor
@Observable
final class AppState {
    var globalAppearance: AppearanceConfig {
        didSet { persistAppearance() }
    }
    let workoutStore: WorkoutStore

    private static let appearanceDefaultsKey = "dev.camminady.openstoptimer.globalAppearance"
    /// Launch argument UI tests pass so each test run starts from a clean
    /// slate (no leftover workouts or settings from a previous run).
    static let uiTestingResetArgument = "-uiTestingReset"

    init(workoutStore: WorkoutStore = WorkoutStore()) {
        self.workoutStore = workoutStore

        if ProcessInfo.processInfo.arguments.contains(Self.uiTestingResetArgument) {
            UserDefaults.standard.removeObject(forKey: Self.appearanceDefaultsKey)
            workoutStore.deleteAll()
        }

        if let data = UserDefaults.standard.data(forKey: Self.appearanceDefaultsKey),
           let decoded = try? JSONDecoder().decode(AppearanceConfig.self, from: data) {
            globalAppearance = decoded
        } else {
            globalAppearance = .default
        }
    }

    private func persistAppearance() {
        guard let data = try? JSONEncoder().encode(globalAppearance) else { return }
        UserDefaults.standard.set(data, forKey: Self.appearanceDefaultsKey)
    }
}
