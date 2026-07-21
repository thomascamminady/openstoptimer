import SwiftUI
import OpenStopTimerKit

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let appState: AppState
    @State private var selectedDestination: AppDestination?

    var body: some View {
        Group {
            // Both size classes regular means an actual iPad (in either
            // orientation). A big iPhone in landscape is regular-width but
            // *compact*-height — giving it the sidebar too left the timer
            // screens fighting a sidebar column for width on an already
            // short screen, which is what made landscape feel broken.
            if horizontalSizeClass == .regular, verticalSizeClass == .regular {
                NavigationSplitView {
                    List(selection: $selectedDestination) {
                        ForEach(AppDestination.allCases) { destination in
                            Label(destination.title, systemImage: destination.systemImage)
                                .tag(destination)
                        }
                    }
                    .navigationTitle("OpenStopTimer")
                } detail: {
                    NavigationStack {
                        if let selectedDestination {
                            destinationView(for: selectedDestination)
                        } else {
                            ContentUnavailableView("Pick a Mode", systemImage: "timer")
                        }
                    }
                }
            } else {
                NavigationStack {
                    HomeView()
                        .navigationDestination(for: AppDestination.self, destination: destinationView)
                }
            }
        }
        .environment(appState)
        .onOpenURL(perform: handleOpenURL)
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .simpleTimer: SimpleTimerView()
        case .simpleStopwatch: SimpleStopwatchView()
        case .lapStopwatch: LapStopwatchView()
        case .hiit: HIITLibraryView(appState: appState)
        case .metronome: MetronomeView(appState: appState)
        case .settings: SettingsView()
        }
    }

    /// Handles the Files-app "Open in OpenStopTimer" / AirDrop-receive case:
    /// import straight into the library and jump to the HIIT tab.
    private func handleOpenURL(_ url: URL) {
        selectedDestination = .hiit
        guard let workout = try? WorkoutImporter.importWorkout(from: url) else { return }
        try? appState.workoutStore.save(workout)
    }
}

#Preview {
    RootView(appState: AppState())
}
