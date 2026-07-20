import Foundation
import Observation
import OpenStopTimerKit

/// Zero-configuration count-up stopwatch: start, stop, reset. No laps, no
/// settings — the "kitchen timer's sibling" for open-ended counting.
@MainActor
@Observable
final class SimpleStopwatchModel {
    private(set) var displayedElapsed: TimeInterval = 0

    private var engine: TimerEngine?
    private var tickTask: Task<Void, Never>?

    var hasStarted: Bool { engine != nil }
    var isPaused: Bool { engine?.isPaused ?? false }
    var isRunning: Bool { engine?.isRunning ?? false }

    func start() {
        let engine = TimerEngine(direction: .countUp)
        self.engine = engine
        engine.start()
        startTicking()
    }

    func togglePause() {
        guard let engine else { return }
        if engine.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.displayedElapsed = self.engine?.elapsed ?? 0
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }
}
