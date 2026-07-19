import Foundation
import Observation
import OpenStopTimerKit

/// Zero-configuration countdown timer: pick a duration, start, get alerted
/// at zero. Uses fixed sensible defaults rather than the full appearance
/// system — this mode is meant to require no explanation at all.
@MainActor
@Observable
final class SimpleTimerModel {
    var selectedDuration: TimeInterval = 60

    private(set) var displayedRemaining: TimeInterval = 60
    private(set) var isFinished: Bool = false

    private var engine: TimerEngine?
    private var tickTask: Task<Void, Never>?
    private let notificationScheduler = NotificationScheduler()

    var hasStarted: Bool { engine != nil }
    var isPaused: Bool { engine?.isPaused ?? false }
    var isRunning: Bool { engine?.isRunning ?? false }

    func start() {
        guard selectedDuration > 0 else { return }
        let engine = TimerEngine(direction: .countDown(duration: selectedDuration))
        self.engine = engine
        engine.start()
        isFinished = false
        displayedRemaining = selectedDuration
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

    func reset() {
        tickTask?.cancel()
        tickTask = nil
        engine = nil
        isFinished = false
        displayedRemaining = selectedDuration
        notificationScheduler.cancelAll()
    }

    private func startTicking() {
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while let self, !Task.isCancelled {
                self.refreshFromEngine()
                if self.isFinished { break }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
    }

    private func refreshFromEngine() {
        guard let engine else { return }
        displayedRemaining = engine.remaining ?? 0
        if engine.isFinished, !isFinished {
            isFinished = true
            SoundPlayer.shared.play(AppearanceConfig.default.sound(for: .workoutComplete))
            Haptics.success()
        }
    }

    /// Called from the view on `scenePhase` changes so a locked/backgrounded
    /// countdown still alerts the user at the right moment.
    func handleScenePhase(isActive: Bool) {
        guard let engine, engine.isRunning, let finishDate = engine.projectedFinishDate else {
            if isActive { notificationScheduler.cancelAll() }
            return
        }
        if isActive {
            notificationScheduler.cancelAll()
        } else {
            Task {
                await notificationScheduler.requestAuthorizationIfNeeded()
                await notificationScheduler.scheduleSimpleTimerCompletion(finishDate: finishDate, appearance: .default)
            }
        }
    }
}
