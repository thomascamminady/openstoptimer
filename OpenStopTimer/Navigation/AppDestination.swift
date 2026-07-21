import Foundation

enum AppDestination: String, CaseIterable, Identifiable, Hashable {
    case simpleTimer
    case simpleStopwatch
    case lapStopwatch
    case hiit
    case metronome
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simpleTimer: "Simple Timer"
        case .simpleStopwatch: "Simple Stopwatch"
        case .lapStopwatch: "Lap Stopwatch"
        case .hiit: "Advanced Workouts"
        case .metronome: "Metronome"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .simpleTimer: "timer"
        case .simpleStopwatch: "stopwatch"
        case .lapStopwatch: "flag.checkered"
        case .hiit: "flame.fill"
        case .metronome: "metronome"
        case .settings: "gearshape"
        }
    }
}
