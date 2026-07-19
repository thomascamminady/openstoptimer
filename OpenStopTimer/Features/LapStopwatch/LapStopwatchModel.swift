import Foundation
import Observation
import OpenStopTimerKit

/// The advanced, configurable stopwatch: count-up plus lap recording, honoring
/// the shared `AppearanceConfig` (colors/sounds/fonts) like the HIIT player.
@MainActor
@Observable
final class LapStopwatchModel {
    private(set) var displayedElapsed: TimeInterval = 0
    private(set) var laps: [LapRecord] = []
    var appearance: AppearanceConfig = .default

    private var engine: TimerEngine?
    private var tickTask: Task<Void, Never>?

    var hasStarted: Bool { engine != nil }
    var isPaused: Bool { engine?.isPaused ?? false }
    var isRunning: Bool { engine?.isRunning ?? false }

    var fastestLapID: UUID? {
        guard laps.count > 1 else { return nil }
        return laps.min(by: { $0.lapTime < $1.lapTime })?.id
    }
    var slowestLapID: UUID? {
        guard laps.count > 1 else { return nil }
        return laps.max(by: { $0.lapTime < $1.lapTime })?.id
    }

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

    func recordLap() {
        guard let engine, engine.isRunning else { return }
        let cumulative = engine.elapsed
        let previous = laps.last?.cumulativeTime ?? 0
        laps.append(LapRecord(index: laps.count + 1, lapTime: cumulative - previous, cumulativeTime: cumulative))
        SoundPlayer.shared.play(appearance.sound(for: .phaseEnd))
    }

    func reset() {
        tickTask?.cancel()
        tickTask = nil
        engine = nil
        displayedElapsed = 0
        laps = []
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
