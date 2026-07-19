import SwiftUI
import OpenStopTimerKit

struct HIITPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: HIITPlayerModel

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
    }

    @ViewBuilder
    private var display: some View {
        if model.isFinished {
            finishedView
        } else if let current = model.currentStep, model.hasStarted {
            VStack(spacing: 0) {
                progressBar
                CurrentNextPanel(
                    currentName: current.name,
                    currentColor: current.color.color,
                    currentRemaining: model.displayedRemainingInStep,
                    nextName: model.nextStep?.name,
                    nextColor: model.nextStep?.color.color,
                    ratio: model.appearance.currentNextRatio,
                    fontScale: model.appearance.fontScale
                )
            }
        } else {
            summaryView
        }
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
                    Spacer()
                    Text("\(Int(step.duration))s").foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
        .padding(.top)
    }

    private var finishedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Workout Complete!")
                .font(.title.bold())
            Text(TimeFormatting.clock(model.workout.totalDuration))
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("hiitPlayer.doneButton")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("hiitPlayer.finishedView")
    }

    private func primaryAction() {
        if !model.hasStarted {
            model.start()
        } else {
            model.togglePause()
        }
    }
}
