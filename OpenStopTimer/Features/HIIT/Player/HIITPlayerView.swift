import SwiftUI
import OpenStopTimerKit

struct HIITPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState
    @State private var model: HIITPlayerModel
    @State private var isEditingWorkout = false

    init(workout: HIITWorkout, appearance: AppearanceConfig) {
        _model = State(initialValue: HIITPlayerModel(workout: workout, appearance: appearance))
    }

    var body: some View {
        AdaptiveTimerLayout {
            display
        } controls: {
            if !model.isFinished {
                PlayerControls(
                    hasStarted: model.hasStarted,
                    isPaused: model.isPaused,
                    showsSkip: model.hasStarted,
                    onPrimary: primaryAction,
                    onReset: model.reset,
                    onSkipBack: model.skipPrevious,
                    onSkipForward: model.skipNext
                )
            }
        }
        .navigationTitle(model.workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .keepScreenAwake(while: model.isRunning)
        .onChange(of: scenePhase) { _, newValue in
            model.handleScenePhase(isActive: newValue == .active)
        }
        // The countdown ticks several times a second; a snappier, non-animated
        // update reads better for a fast-paced interval timer than SwiftUI's
        // default implicit cross-fade on every state/view-type change.
        .transaction { $0.disablesAnimations = true }
        .toolbar {
            if !model.hasStarted {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditingWorkout = true }
                        .accessibilityIdentifier("hiitPlayer.editButton")
                }
            }
        }
        .sheet(isPresented: $isEditingWorkout) {
            NavigationStack {
                HIITEditorView(workout: model.workout, store: appState.workoutStore) {
                    // The workout just changed under us; rather than try to
                    // hot-reload a possibly-already-configured player, pop
                    // back to the library so the user re-opens the fresh copy.
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var display: some View {
        if model.isFinished {
            finishedView
        } else if let current = model.currentStep, model.hasStarted {
            VStack(spacing: 0) {
                progressBar
                Text("Step \(model.currentStepIndex + 1) of \(model.steps.count)")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("hiitPlayer.stepCounter")
                CurrentNextPanel(
                    currentName: current.name,
                    currentColor: current.color.color,
                    currentRemaining: model.displayedRemainingInStep,
                    nextName: model.nextStep?.name,
                    nextColor: model.nextStep?.color.color,
                    progressText: progressText(for: current),
                    ratio: model.appearance.currentNextRatio,
                    fontScale: model.appearance.fontScale
                )
            }
        } else {
            summaryView
        }
    }

    private func progressText(for step: WorkoutStep) -> String? {
        guard let progress = step.roundProgress else { return nil }
        if progress.totalSets > 1 {
            return "SET \(progress.set)/\(progress.totalSets) · ROUND \(progress.round)/\(progress.totalRounds)"
        }
        return "ROUND \(progress.round)/\(progress.totalRounds)"
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            let progress = model.steps.isEmpty ? 0 : Double(model.currentStepIndex + 1) / Double(model.steps.count)
            Rectangle()
                .fill(Color.primary.opacity(0.15))
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.4))
                        .frame(width: proxy.size.width * progress)
                }
        }
        .frame(height: 4)
    }

    private var summaryView: some View {
        VStack(spacing: 16) {
            Text(model.workout.name)
                .font(.largeTitle.bold())
            Text("\(model.steps.count) steps · \(TimeFormatting.clock(model.workout.totalDuration))")
                .foregroundStyle(.secondary)
            List(model.steps) { step in
                HStack {
                    Circle().fill(step.color.color).frame(width: 10, height: 10)
                    Text(step.name)
                    if let progress = step.roundProgress {
                        Text("\(progress.round)/\(progress.totalRounds)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(Int(step.duration))s").foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
        .padding(.top)
    }

    private var finishedView: some View {
        // NB: don't also put an identifier on the enclosing VStack — a
        // container identifier shadows its children's own identifiers in the
        // accessibility tree (learned the hard way via UI test debugging).
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Workout Complete!")
                .font(.title.bold())
                .accessibilityIdentifier("hiitPlayer.finishedView")
            Text(TimeFormatting.clock(model.workout.totalDuration))
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("hiitPlayer.doneButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func primaryAction() {
        if !model.hasStarted {
            model.start()
        } else {
            model.togglePause()
        }
    }
}
