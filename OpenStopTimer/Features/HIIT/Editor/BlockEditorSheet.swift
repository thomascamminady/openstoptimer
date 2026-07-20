import SwiftUI
import OpenStopTimerKit

struct BlockSummaryRow: View {
    let block: HIITBlock

    var body: some View {
        switch block {
        case .step(let step):
            HStack {
                Circle().fill(step.color.color).frame(width: 10, height: 10)
                Text(step.name)
                Spacer()
                Text("\(Int(step.duration))s").foregroundStyle(.secondary)
            }

        case .roundGroup(let group):
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name?.isEmpty == false ? group.name! : loopDescription(group))
                    .fontWeight(.semibold)
                Text(exerciseSummary(group))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private func loopDescription(_ group: HIITBlock.RoundGroup) -> String {
        group.sets > 1 ? "\(group.sets) sets \u{00d7} \(group.rounds) rounds" : "\(group.rounds) rounds"
    }

    private func exerciseSummary(_ group: HIITBlock.RoundGroup) -> String {
        let exercises = group.exercises
            .map { "\($0.name) \(Int($0.duration))s" }
            .joined(separator: " / ")
        if let rest = group.restBetweenRounds {
            return "\(exercises) · Rest \(Int(rest.duration))s"
        }
        return exercises
    }
}

struct BlockEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var block: HIITBlock

    var body: some View {
        Form {
            switch block {
            case .step:
                stepEditor
            case .roundGroup:
                roundGroupEditor
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("blockEditor.doneButton")
            }
        }
    }

    private var navigationTitle: String {
        switch block {
        case .step: "Edit Step"
        case .roundGroup: "Edit Interval"
        }
    }

    @ViewBuilder
    private var stepEditor: some View {
        if case .step(let step) = block {
            StepFields(step: Binding(get: { step }, set: { block = .step($0) }))
        }
    }

    @ViewBuilder
    private var roundGroupEditor: some View {
        if case .roundGroup(let group) = block {
            RoundGroupFields(group: Binding(get: { group }, set: { block = .roundGroup($0) }))
        }
    }
}

private struct StepFields: View {
    @Binding var step: WorkoutStep

    var body: some View {
        Section("Details") {
            TextField("Name", text: $step.name)
                .accessibilityIdentifier("blockEditor.stepNameField")
            Picker("Type", selection: $step.kind) {
                ForEach(PhaseKind.allCases) { kind in
                    Text(kind.displayName).tag(kind)
                }
            }
            Stepper("Duration: \(Int(step.duration))s", value: $step.duration, in: 1...600, step: 5)
        }
    }
}

private struct RoundGroupFields: View {
    @Binding var group: HIITBlock.RoundGroup

    var body: some View {
        Section("Name") {
            TextField(
                "Optional, e.g. \"Sprints\"",
                text: Binding(get: { group.name ?? "" }, set: { group.name = $0.isEmpty ? nil : $0 })
            )
            .accessibilityIdentifier("blockEditor.groupNameField")
        }

        Section("Exercises") {
            ForEach($group.exercises) { $exercise in
                VStack(alignment: .leading) {
                    TextField("Name", text: $exercise.name)
                    Stepper("Duration: \(Int(exercise.duration))s", value: $exercise.duration, in: 1...600, step: 5)
                }
            }
            .onDelete { offsets in
                // Always leave at least one exercise — a round group with
                // none produces zero playable steps.
                guard group.exercises.count > offsets.count else { return }
                group.exercises.remove(atOffsets: offsets)
            }

            Button("Add Exercise") {
                group.exercises.append(
                    WorkoutStep(name: "Exercise \(group.exercises.count + 1)", kind: .work, duration: 30)
                )
            }
            .accessibilityIdentifier("blockEditor.addExercise")
        }

        if group.exercises.count > 1 {
            Section("Rest Between Exercises") {
                RestToggleFields(rest: $group.restBetweenExercises, defaultDuration: 10)
            }
        }

        Section("Rounds") {
            Stepper("Rounds: \(group.rounds)", value: $group.rounds, in: 1...50)
                .accessibilityIdentifier("blockEditor.roundsStepper")
        }

        Section("Rest Between Rounds") {
            RestToggleFields(rest: $group.restBetweenRounds, defaultDuration: 20)
        }

        Section {
            Stepper("Sets: \(group.sets)", value: $group.sets, in: 1...20)
                .accessibilityIdentifier("blockEditor.setsStepper")
        } header: {
            Text("Sets")
        } footer: {
            Text("Repeats the whole block of rounds again — e.g. Rounds: 10, Sets: 3 plays \"3x10\".")
        }

        if group.sets > 1 {
            Section("Rest Between Sets") {
                RestToggleFields(rest: $group.restBetweenSets, defaultDuration: 60)
            }
        }
    }
}

private struct RestToggleFields: View {
    @Binding var rest: WorkoutStep?
    let defaultDuration: TimeInterval

    var body: some View {
        Toggle("Enabled", isOn: Binding(
            get: { rest != nil },
            set: { isOn in
                rest = isOn ? WorkoutStep(name: "Rest", kind: .rest, duration: defaultDuration) : nil
            }
        ))
        if rest != nil {
            TextField(
                "Name",
                text: Binding(get: { rest?.name ?? "Rest" }, set: { rest?.name = $0 })
            )
            Stepper(
                "Duration: \(Int(rest?.duration ?? defaultDuration))s",
                value: Binding(
                    get: { rest?.duration ?? defaultDuration },
                    set: { rest?.duration = $0 }
                ),
                in: 1...300,
                step: 5
            )
        }
    }
}
