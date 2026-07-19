import SwiftUI

/// The compact-width (iPhone) landing screen: four big, unmissable cards —
/// the two "simple" modes need no explanation, the two advanced ones invite
/// exploration.
struct HomeView: View {
    private let modeDestinations: [AppDestination] = [.simpleTimer, .simpleStopwatch, .lapStopwatch, .hiit]
    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(modeDestinations) { destination in
                    NavigationLink(value: destination) {
                        ModeCard(destination: destination)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("home.card.\(destination.rawValue)")
                }
            }
            .padding()
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
}

private struct ModeCard: View {
    let destination: AppDestination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: destination.systemImage)
                .font(.system(size: 30, weight: .semibold))
            Spacer()
            Text(destination.title)
                .font(.headline)
            Text(destination.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(height: 150, alignment: .topLeading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    NavigationStack { HomeView() }
}
