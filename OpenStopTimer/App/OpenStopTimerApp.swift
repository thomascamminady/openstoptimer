import SwiftUI

@main
struct OpenStopTimerApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView(appState: appState)
                .task {
                    // Pay the one-time audio-session/file-decode cost here,
                    // asynchronously after the first frame, rather than
                    // letting it stall a player's first "Start" tap.
                    SoundPlayer.shared.preload()
                }
        }
    }
}
