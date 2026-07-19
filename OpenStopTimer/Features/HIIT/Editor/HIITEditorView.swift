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

            Section("Steps") {
                if model.workout.blocks.isEmpty {
                    Text("No steps yet — add a step or a round group below.")
                        .foregroundStyle(.secondary)
                }
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
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("Add Work Step") { model.addStep(kind: .work, duration: 30) }
                        .accessibilityIdentifier("hiitEditor.addWorkStep")
                    Button("Add Rest Step") { model.addStep(kind: .rest, duration: 15) }
                        .accessibilityIdentifier("hiitEditor.addRestStep")
                    Button("Add Round Group") { model.addRoundGroup() }
                        .accessibilityIdentifier("hiitEditor.addRoundGroup")
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityIdentifier("hiitEditor.addMenu")
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("hiitEditor.cancelButton")
            }
            ToolbarItem(placement: .primaryAction) {
                EditButton()
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

    private var isEditingBlock: Binding<Bool> {
        Binding(get: { editingBlockID != nil }, set: { if !$0 { editingBlockID = nil } })
    }
}

#Preview {
    NavigationStack {
        HIITEditorView(workout: .exampleTabata(), store: WorkoutStore(), onSave: {})
    }
}
