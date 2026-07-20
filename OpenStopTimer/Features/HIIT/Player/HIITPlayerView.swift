import SwiftUI
import OpenStopTimerKit

struct HIITPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppState.self) private var appState
    @State private var model: HIITPlayerModel
    @State private var isEditingWorkout = false

    private let upcomingLookahead = 4

    init(workout: HIITWorkout, appearance: AppearanceConfig) {
        _model = State(initialValue: HIITPlayerModel(workout: workout, appearance: appearance))
    }

    var body: some View {
        AdaptiveTimerLayout {
            display
        } controls: {
            controlsView
        }
        // No workout-name title — every pixel here is screen real estate
        // that matters for the countdown, especially in landscape. The
        // whole nav bar disappears once a session is actually running, in
        // favor of the in-content Back button below.
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(model.hasStarted && !model.isFinished ? .hidden : .visible, for: .navigationBar)
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
    private var controlsView: some View {
        if !model.isFinished {
            VStack(spacing: 16) {
                PlayerControls(
                    hasStarted: model.hasStarted,
                    isPaused: model.isPaused,
                    showsSkip: model.hasStarted,
                    showsReset: false,
                    onPrimary: primaryAction,
                    onSkipBack: model.skipPrevious,
                    onSkipForward: model.skipNext
                )
                // A second row below skip/pause/skip — "Back" exits to the
                // library (replacing the now-hidden nav bar's back chevron),
                // "Replay" restarts the same workout from the top.
                if model.hasStarted {
                    HStack(spacing: 40) {
                        exitReplayButton(title: "Back", systemImage: "chevron.left", identifier: "hiitPlayer.backButton") {
                            dismiss()
                        }
                        exitReplayButton(title: "Replay", systemImage: "arrow.counterclockwise", identifier: "playerControls.reset") {
                            model.reset()
                        }
                    }
                }
            }
        }
    }

    private func exitReplayButton(title: String, systemImage: String, identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .accessibilityIdentifier(identifier)
    }

    @ViewBuilder
    private var display: some View {
        if model.isFinished {
            finishedView
        } else if let current = model.currentStep, model.hasStarted {
            GeometryReader { proxy in
                VStack(spacing: 8) {
                    CurrentStepView(
                        name: current.name,
                        color: model.appearance.color(for: current.kind).color,
                        remaining: model.displayedRemainingInStep,
                        progressText: activeProgressText(for: current),
                        fontScale: model.appearance.fontScale
                    )
                    if !upcomingItems.isEmpty {
                        // `currentNextRatio` (Settings > Display > "Current /
                        // Next Balance") is the fraction of this whole area
                        // the current-step display gets; the strip gets the
                        // rest, with a floor so tiles stay legible even at
                        // the ratio's high end.
                        UpcomingStepsStrip(items: upcomingItems)
                            .padding(.horizontal, 8)
                            .frame(height: stripHeight(in: proxy.size.height))
                    }
                }
            }
        } else {
            summaryView
        }
    }

    /// Shown on the big current-step display — only while a work step is
    /// active; during rest it's suppressed since rest isn't itself a round.
    private func activeProgressText(for step: WorkoutStep) -> String? {
        guard step.kind == .work, let progress = step.roundProgress else { return nil }
        if progress.totalSets > 1 {
            return "SET \(progress.set)/\(progress.totalSets) · ROUND \(progress.round)/\(progress.totalRounds)"
        }
        return "ROUND \(progress.round)/\(progress.totalRounds)"
    }

    /// Shown on an upcoming-step chip — a work chip previews its round
    /// number (e.g. "2/10") so mid-rest you can see what's coming.
    private func chipProgressText(for step: WorkoutStep) -> String? {
        guard step.kind == .work, let progress = step.roundProgress else { return nil }
        return "\(progress.round)/\(progress.totalRounds)"
    }

    private func stripHeight(in availableHeight: CGFloat) -> CGFloat {
        let raw = availableHeight * (1 - model.appearance.currentNextRatio)
        return min(max(raw, 72), 140)
    }

    private var upcomingItems: [UpcomingStepsStrip.Item] {
        let upcoming = model.steps[(model.currentStepIndex + 1)...].prefix(upcomingLookahead)
        return upcoming.map { step in
            UpcomingStepsStrip.Item(
                id: step.id,
                name: step.name,
                color: model.appearance.color(for: step.kind).color,
                duration: step.duration,
                roundText: chipProgressText(for: step)
            )
        }
    }

    private var summaryView: some View {
        VStack(spacing: 16) {
            Text(model.workout.name)
                .font(.largeTitle.bold())
            Text("\(model.steps.count) steps · \(TimeFormatting.clock(model.workout.totalDuration))")
                .foregroundStyle(.secondary)
            List(model.steps) { step in
                HStack {
                    Circle().fill(model.appearance.color(for: step.kind).color).frame(width: 10, height: 10)
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
