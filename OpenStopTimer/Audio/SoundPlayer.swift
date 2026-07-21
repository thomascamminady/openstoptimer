import AVFoundation
import OpenStopTimerKit

/// Plays the bundled beep/chime/bell assets for in-app (foreground) events.
/// Deliberately the only way this app ever makes noise or vibrates — there
/// is no local-notification scheduling anywhere, so it never posts a system
/// alert/banner, and it never plays anything while backgrounded/suspended.
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    private var players: [SoundChoice: AVAudioPlayer] = [:]

    private init() {
        // `.playback` (not `.ambient`) is what actually makes these beeps
        // audible with the ring/silent switch flipped to silent — the
        // normal state for a phone in a runner's pocket, and exactly when
        // this app's sound matters most. `.mixWithOthers` still lets
        // whatever music/podcast the user has playing keep playing under it.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.mixWithOthers])
        try? session.setActive(true)
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
