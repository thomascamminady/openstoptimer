import SwiftUI
import OpenStopTimerKit

struct HIITEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
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
                            BlockSummaryRow(block: block, appearance: appState.globalAppearance)
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

            appearanceSection
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
                AddBlockButton(title: "Warm Up", systemImage: "figure.walk", identifier: "hiitEditor.addWarmup") {
                    model.addWarmup()
                }
                AddBlockButton(title: "Interval", systemImage: "repeat", identifier: "hiitEditor.addRoundGroup") {
                    editingBlockID = model.addRoundGroup()
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
        // Deliberately no listRowInsets override here — that previously
        // zeroed the leading/trailing insets too, so the buttons sat flush
        // against the section's edges while every sibling row (Name field,
        // footer text, Steps rows) kept the normal margin. Just add a touch
        // of extra vertical breathing room on top of the default insets.
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
    }

    private var isEditingBlock: Binding<Bool> {
        Binding(get: { editingBlockID != nil }, set: { if !$0 { editingBlockID = nil } })
    }

    /// Lets this workout override any of Settings' global appearance
    /// defaults (colors, text size, current/next balance, sounds, haptics).
    /// Only the fields actually touched here are stored — anything left
    /// alone keeps tracking whatever Settings says, even after this save.
    private var appearanceSection: some View {
        Section {
            Toggle("Customize Appearance for This Workout", isOn: appearanceOverrideEnabledBinding)
                .accessibilityIdentifier("hiitEditor.appearanceOverrideToggle")

            if model.workout.appearanceOverride != nil {
                ForEach(PhaseKind.allCases) { phase in
                    ColorPicker(
                        phase.displayName,
                        selection: WorkoutAppearanceModel.colorBinding(appearanceOverrideBinding, global: appState.globalAppearance, for: phase)
                    )
                }

                VStack(alignment: .leading) {
                    Text("Number Height: \(String(format: "%.0f%%", WorkoutAppearanceModel.fontScaleBinding(appearanceOverrideBinding, global: appState.globalAppearance).wrappedValue * 100))")
                    Slider(value: WorkoutAppearanceModel.fontScaleBinding(appearanceOverrideBinding, global: appState.globalAppearance), in: 0.3...1.0, step: 0.05)
                }
                VStack(alignment: .leading) {
                    Text("Current / Next Balance")
                    Slider(value: WorkoutAppearanceModel.currentNextRatioBinding(appearanceOverrideBinding, global: appState.globalAppearance), in: 0.5...0.95, step: 0.05)
                }

                Toggle("Sounds Enabled", isOn: WorkoutAppearanceModel.soundsEnabledBinding(appearanceOverrideBinding, global: appState.globalAppearance))
                if WorkoutAppearanceModel.soundsEnabledBinding(appearanceOverrideBinding, global: appState.globalAppearance).wrappedValue {
                    ForEach(SoundEvent.allCases) { event in
                        Picker(
                            event.displayName,
                            selection: WorkoutAppearanceModel.soundBinding(appearanceOverrideBinding, global: appState.globalAppearance, for: event)
                        ) {
                            ForEach(SoundChoice.allCases) { choice in
                                Text(choice.displayName).tag(choice)
                            }
                        }
                    }
                }

                Toggle("Haptics Enabled", isOn: WorkoutAppearanceModel.hapticsEnabledBinding(appearanceOverrideBinding, global: appState.globalAppearance))
            }
        } header: {
            Text("Appearance")
        } footer: {
            Text("Overrides the global colors, text size, and sounds from Settings for just this workout.")
        }
    }

    private var appearanceOverrideEnabledBinding: Binding<Bool> {
        Binding(
            get: { model.workout.appearanceOverride != nil },
            set: { isOn in model.workout.appearanceOverride = isOn ? AppearanceOverride() : nil }
        )
    }

    private var appearanceOverrideBinding: Binding<AppearanceOverride> {
        Binding(
            get: { model.workout.appearanceOverride ?? AppearanceOverride() },
            set: { model.workout.appearanceOverride = $0 }
        )
    }
}

private struct AddBlockButton: View {
    let title: String
    let systemImage: String
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 26, weight: .semibold))
                Text(title)
                    .font(.callout.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(.tint.opacity(0.35), lineWidth: 1.5)
            )
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
