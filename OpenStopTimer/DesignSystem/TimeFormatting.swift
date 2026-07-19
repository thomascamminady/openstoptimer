import Foundation

enum TimeFormatting {
    /// "MM:SS" or "H:MM:SS" for durations at or above an hour.
    static func clock(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// "MM:SS.d" — used by the stopwatches, which want sub-second precision.
    static func clockWithTenths(_ interval: TimeInterval) -> String {
        let clamped = max(0, interval)
        let totalTenths = Int((clamped * 10).rounded())
        let minutes = (totalTenths / 10) / 60
        let seconds = (totalTenths / 10) % 60
        let tenths = totalTenths % 10
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}
