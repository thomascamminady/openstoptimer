import SwiftUI
import OpenStopTimerKit

struct HIITEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: HIITEditorModel
    @State private var editingBlockID: HIITBlock.ID?

    init(workout: HIITWorkout, store: WorkoutStore, onSave: @escaping () -> Void) {
        _model = State(initialValue: HIITEditorModel(workout: workout, store: store, onSave: onSave))
    }

    var body: some View {
        Form {
            Section("Name") {
                TextField("Workout Name", text: $model.workout.name)
                    .accessibilityIdentifier("hiitEditor.nameField")
            }

            Section {
                addBlockRow
            } footer: {
                Text("An interval is a work/rest pair repeated N times — optionally repeated again as multiple sets, e.g. \"3x10\" for 3 sets of 10 rounds.")
            }

            if !model.workout.blocks.isEmpty {
                Section("Steps") {
                    ForEach(model.workout.blocks) { block in
                        Button {
                            editingBlockID = block.id
                        } label: {
                            BlockSummaryRow(block: block)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: model.removeBlocks)
                    .onMove(perform: model.moveBlocks)
                }

                Section {
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text(TimeFormatting.clock(model.workout.totalDuration))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(model.workout.name.isEmpty ? "New Workout" : model.workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    model.save()
                    dismiss()
                }
                .disabled(!model.canSave)
                .accessibilityIdentifier("hiitEditor.saveButton")
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("hiitEditor.cancelButton")
            }
            if !model.workout.blocks.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
        }
        .sheet(isPresented: isEditingBlock) {
            if let index = model.workout.blocks.firstIndex(where: { $0.id == editingBlockID }) {
                NavigationStack {
                    BlockEditorSheet(block: $model.workout.blocks[index])
                }
            }
        }
    }

    /// The three common building blocks, always on screen as big obvious
    /// buttons — no menu to hunt through. A "single step" fallback for rarer
    /// custom cases sits below, visually secondary.
    private var addBlockRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                AddBlockButton(title: "Interval", systemImage: "repeat", identifier: "hiitEditor.addRoundGroup") {
                    editingBlockID = model.addRoundGroup()
                }
                AddBlockButton(title: "Warm Up", systemImage: "figure.walk", identifier: "hiitEditor.addWarmup") {
                    model.addWarmup()
                }
                AddBlockButton(title: "Cool Down", systemImage: "wind", identifier: "hiitEditor.addCooldown") {
                    model.addCooldown()
                }
            }

            Menu {
                Button("Add Single Work Step") { model.addStep(kind: .work, duration: 30) }
                    .accessibilityIdentifier("hiitEditor.addWorkStep")
                Button("Add Single Rest Step") { model.addStep(kind: .rest, duration: 15) }
                    .accessibilityIdentifier("hiitEditor.addRestStep")
            } label: {
                Text("Add a single custom step…")
                    .font(.footnote)
            }
            .accessibilityIdentifier("hiitEditor.addMenu")
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
    }

    private var isEditingBlock: Binding<Bool> {
        Binding(get: { editingBlockID != nil }, set: { if !$0 { editingBlockID = nil } })
    }
}

private struct AddBlockButton: View {
    let title: String
    let systemImage: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }
}

#Preview {
    NavigationStack {
        HIITEditorView(workout: .exampleTabata(), store: WorkoutStore(), onSave: {})
    }
}
