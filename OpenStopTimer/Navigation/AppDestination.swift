import Foundation

enum AppDestination: String, CaseIterable, Identifiable, Hashable {
    case simpleTimer
    case simpleStopwatch
    case lapStopwatch
    case hiit
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simpleTimer: "Simple Timer"
        case .simpleStopwatch: "Simple Stopwatch"
        case .lapStopwatch: "Lap Stopwatch"
        case .hiit: "HIIT Workouts"
        case .settings: "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .simpleTimer: "Set it and go"
        case .simpleStopwatch: "Start, stop, reset"
        case .lapStopwatch: "Track splits"
        case .hiit: "Build & run intervals"
        case .settings: "Colors, sounds & more"
        }
    }

    var systemImage: String {
        switch self {
        case .simpleTimer: "timer"
        case .simpleStopwatch: "stopwatch"
        case .lapStopwatch: "flag.checkered"
        case .hiit: "flame.fill"
        case .settings: "gearshape"
        }
    }
}
