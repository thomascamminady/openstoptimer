import AVFoundation
import OpenStopTimerKit

/// Plays the bundled beep/chime/bell assets for in-app (foreground) events.
/// Background alerting is handled separately by `NotificationScheduler`,
/// which reuses the same bundled files as notification sounds.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [SoundChoice: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    /// Decodes every bundled sound up front. Call this once, early (e.g. at
    /// app launch) — without it, the *first* `play(_:)` call in the app's
    /// lifetime pays for session activation and file decoding synchronously
    /// on the main thread, which can noticeably stall whatever UI action
    /// triggered it (a player's first "Start" tap is a bad place to first
    /// discover that cost).
    func preload() {
        for choice in SoundChoice.allCases {
            _ = player(for: choice)
        }
    }

    /// Fire-and-forget: deliberately does not block the caller. AVAudioPlayer
    /// / audio-session work has been observed to stall unpredictably (most
    /// visibly on the Simulator), and sound must never be allowed to freeze
    /// the UI at exactly the moment — a phase transition — when
    /// responsiveness matters most. Deferring the actual `.play()` onto a
    /// following main-actor turn keeps the caller's state-update code (which
    /// is what SwiftUI is waiting on to re-render) on the fast path.
    func play(_ choice: SoundChoice) {
        Task { [weak self] in
            guard let player = self?.player(for: choice) else { return }
            player.currentTime = 0
            player.play()
        }
    }

    private func player(for choice: SoundChoice) -> AVAudioPlayer? {
        guard let resourceName = choice.resourceName else { return nil }
        if let cached = players[choice] {
            return cached
        }
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[choice] = player
        return player
    }
}
