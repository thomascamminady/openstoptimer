import Foundation

/// A moment during a timer session that can play a sound.
public enum SoundEvent: String, Codable, CaseIterable, Sendable, Identifiable {
    case phaseStart
    case countdownTick
    case phaseEnd
    case workoutComplete

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .phaseStart: "Phase Start"
        case .countdownTick: "Countdown Tick"
        case .phaseEnd: "Phase End"
        case .workoutComplete: "Workout Complete"
        }
    }

    public var defaultSound: SoundChoice {
        switch self {
        case .phaseStart: .chime
        case .countdownTick: .beepShort
        case .phaseEnd: .beepDouble
        case .workoutComplete: .bell
        }
    }
}
