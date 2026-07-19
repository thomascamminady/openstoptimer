import Foundation
@testable import OpenStopTimerKit

/// A controllable clock for deterministic timer-math tests — no `sleep()`,
/// no flakiness. `advance(by:)` can jump forward by any amount in one step,
/// which is exactly how we simulate "the app was backgrounded/suspended."
/// `@unchecked` because it's only ever touched from a single test at a time;
/// synchronizing it for real would add nothing but noise.
final class FakeClock: WallClock, @unchecked Sendable {
    private var current: Date

    init(startingAt date: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.current = date
    }

    func now() -> Date { current }

    func advance(by seconds: TimeInterval) {
        current = current.addingTimeInterval(seconds)
    }
}
