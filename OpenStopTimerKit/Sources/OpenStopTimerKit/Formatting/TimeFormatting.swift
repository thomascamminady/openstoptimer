import Foundation

/// Pure, UI-free duration formatting — moved here (not the app target) so
/// its rounding behavior, the one thing that actually matters about a
/// *timer* app, gets real unit test coverage instead of only visual checks.
public enum TimeFormatting {
    /// "MM:SS" or "H:MM:SS" for a *static/settled* value — a workout's
    /// total duration, a saved lap time — where "closest whole-number
    /// representation" is what you want. Nearest-rounding. Not for a live
    /// countdown; see `countdownClock`.
    public static func clock(_ interval: TimeInterval) -> String {
        format(totalSeconds: max(0, Int(interval.rounded())))
    }

    /// "MM:SS" or "H:MM:SS" for a *live, ticking-down* countdown's
    /// remaining time. Uses ceiling, not nearest-rounding: with 9.4s left,
    /// you still have to wait through the "9" counting down to zero, so
    /// the display should keep reading "10" until truly at-or-under 9.0s
    /// remain. Nearest-rounding would flip the displayed second up to 0.5s
    /// *before* the true whole-second boundary — a real, perceptible
    /// timing inaccuracy for a screen whose entire job is showing the time
    /// correctly, not just a cosmetic quirk.
    public static func countdownClock(_ interval: TimeInterval) -> String {
        format(totalSeconds: max(0, Int(interval.rounded(.up))))
    }

    private static func format(totalSeconds total: Int) -> String {
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// "MM:SS.d" — used by the stopwatches, which want sub-second
    /// precision. Nearest-rounding to the tenth is the right call here
    /// (unlike the whole-seconds case above): the displayed value already
    /// carries its own sub-second digit, so there's no "flips early"
    /// perceptibility problem to correct for.
    public static func clockWithTenths(_ interval: TimeInterval) -> String {
        let clamped = max(0, interval)
        let totalTenths = Int((clamped * 10).rounded())
        let minutes = (totalTenths / 10) / 60
        let seconds = (totalTenths / 10) % 60
        let tenths = totalTenths % 10
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}
