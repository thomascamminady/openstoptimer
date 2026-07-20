import SwiftUI
import UniformTypeIdentifiers
import OpenStopTimerKit

struct HIITLibraryView: View {
    @Environment(AppState.self) private var appState
    @State private var model: HIITLibraryModel
    @State private var editingWorkout: HIITWorkout?
    @State private var isPresentingImporter = false
    @State private var importErrorMessage: String?

    init(appState: AppState) {
        _model = State(initialValue: HIITLibraryModel(store: appState.workoutStore))
    }

    var body: some View {
        List {
            if model.workouts.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "flame",
                    description: Text("Tap + to build your first HIIT workout.")
                )
            }
            ForEach(model.workouts) { workout in
                NavigationLink(value: workout) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name).font(.headline)
                        Text("\(workout.expandedSteps().count) steps · \(TimeFormatting.clock(workout.totalDuration))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityIdentifier("hiitLibrary.workoutRow.\(workout.name)")
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { model.delete(workout) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    Button { editingWorkout = workout } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                .swipeActions(edge: .leading) {
                    ShareLink(item: workout, preview: SharePreview(workout.name))
                        .tint(.green)
                }
                .contextMenu {
                    Button { editingWorkout = workout } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button { model.duplicate(workout) } label: {
                        Label("Duplicate", systemImage: "plus.square.on.square")
                    }
                    ShareLink(item: workout, preview: SharePreview(workout.name)) {
                        Label("Export…", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(role: .destructive) { model.delete(workout) } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("HIIT Workouts")
        .navigationDestination(for: HIITWorkout.self) { workout in
            HIITPlayerView(workout: workout, appearance: resolvedAppearance(for: workout))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Start empty: the editor's "Add an Interval" empty-state
                    // guides straight into the fast round/set creation flow,
                    // rather than presenting a mystery pre-filled step.
                    editingWorkout = HIITWorkout(name: "New Workout")
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("hiitLibrary.addButton")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    isPresentingImporter = true
                } label: {
                    Label("Import Workout", systemImage: "square.and.arrow.down")
                }
                .accessibilityIdentifier("hiitLibrary.importButton")
            }
        }
        .sheet(item: $editingWorkout) { workout in
            NavigationStack {
                HIITEditorView(workout: workout, store: appState.workoutStore, onSave: { model.reload() })
            }
        }
        .fileImporter(
            isPresented: $isPresentingImporter,
            allowedContentTypes: [.openStopTimerWorkout, .json]
        ) { result in
            handleImport(result)
        }
        .alert(
            "Import Failed",
            isPresented: Binding(get: { importErrorMessage != nil }, set: { if !$0 { importErrorMessage = nil } })
        ) {
            Button("OK") { importErrorMessage = nil }
        } message: {
            Text(importErrorMessage ?? "")
        }
    }

    private func resolvedAppearance(for workout: HIITWorkout) -> AppearanceConfig {
        workout.appearanceOverride?.resolved(against: appState.globalAppearance) ?? appState.globalAppearance
    }

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try model.importWorkout(from: url)
            } catch {
                importErrorMessage = error.localizedDescription
            }
        case .failure(let error):
            importErrorMessage = error.localizedDescription
        }
    }
}
