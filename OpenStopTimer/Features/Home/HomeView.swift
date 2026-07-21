import SwiftUI

/// The compact-width (iPhone) landing screen: five huge, unmissable tiles
/// filling the whole screen — the two "simple" modes need no explanation,
/// the other three invite exploration. No wasted whitespace: picking a mode
/// should be the single, obvious thing to do here.
struct HomeView: View {
    private let modeDestinations: [AppDestination] = [
        .simpleTimer, .simpleStopwatch, .lapStopwatch, .hiit, .metronome
    ]

    var body: some View {
        GeometryReader { proxy in
            let isWide = proxy.size.width > proxy.size.height
            Group {
                if isWide {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            tile(modeDestinations[0])
                            tile(modeDestinations[1])
                            tile(modeDestinations[2])
                        }
                        HStack(spacing: 12) {
                            tile(modeDestinations[3])
                            tile(modeDestinations[4])
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            tile(modeDestinations[0])
                            tile(modeDestinations[1])
                        }
                        HStack(spacing: 12) {
                            tile(modeDestinations[2])
                            tile(modeDestinations[3])
                        }
                        tile(modeDestinations[4])
                    }
                }
            }
            .padding(12)
        }
        .navigationTitle("OpenStopTimer")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(value: AppDestination.settings) {
                    Image(systemName: "gearshape")
                }
                .accessibilityIdentifier("home.settingsButton")
            }
        }
    }

    private func tile(_ destination: AppDestination) -> some View {
        NavigationLink(value: destination) {
            ModeTile(destination: destination)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("home.card.\(destination.rawValue)")
    }
}

private struct ModeTile: View {
    let destination: AppDestination

    var body: some View {
        Text(destination.title)
            .font(.title.weight(.medium))
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.5)
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

#Preview {
    NavigationStack { HomeView() }
}
