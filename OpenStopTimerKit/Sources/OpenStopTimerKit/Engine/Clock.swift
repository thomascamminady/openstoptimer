import Foundation

/// Abstraction over "what time is it right now", so timer math can be tested
/// with a fake clock instead of real `sleep()` calls.
///
/// Named `WallClock` (not `Clock`) to avoid colliding with Swift Concurrency's
/// own `Clock` protocol (`ContinuousClock`, `SuspendingClock`), which measures
/// monotonic time — exactly what we must NOT use as the source of truth here,
/// since a suspended app needs wall-clock (`Date`) time to stay correct.
public protocol WallClock: Sendable {
    func now() -> Date
}

public struct SystemWallClock: WallClock {
    public init() {}
    public func now() -> Date { Date() }
}
