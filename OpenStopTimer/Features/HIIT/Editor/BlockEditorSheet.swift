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
            VStack(alignment: .leading, spacing: 2) {
                Text(group.name ?? "\(group.rounds) Rounds")
                    .fontWeight(.semibold)
                Text(group.exercises.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
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
        .navigationTitle("Edit Step")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
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
        Section("Rounds") {
            Stepper("Rounds: \(group.rounds)", value: $group.rounds, in: 1...50)
        }

        Section("Exercises") {
            ForEach($group.exercises) { $exercise in
                VStack(alignment: .leading) {
                    TextField("Name", text: $exercise.name)
                    Stepper("Duration: \(Int(exercise.duration))s", value: $exercise.duration, in: 1...600, step: 5)
                }
            }
            .onDelete { group.exercises.remove(atOffsets: $0) }

            Button("Add Exercise") {
                group.exercises.append(
                    WorkoutStep(name: "Exercise \(group.exercises.count + 1)", kind: .work, duration: 30)
                )
            }
        }

        Section("Rest Between Exercises") {
            RestToggleFields(rest: $group.restBetweenExercises, defaultDuration: 10)
        }

        Section("Rest Between Rounds") {
            RestToggleFields(rest: $group.restBetweenRounds, defaultDuration: 20)
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
