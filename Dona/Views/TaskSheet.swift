import SwiftUI
import SwiftData

/// Feuille unique pour **créer** _ou_ **modifier** une tâche, inspirée de l’ancien `NewTaskSheet`.
/// - `task == nil`  ➜ création
/// - `task != nil` ➜ édition (préremplissage automatique)
struct TaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // MARK: – Paramètre
    let task: Task?

    // MARK: – États du formulaire
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedPreset: TaskInputPreset = .inbox
    @State private var dueDate: Date = .now

    // MARK: – Init (permet de préremplir les @State dès la création de la vue)
    init(task: Task?) {
        self.task = task
        // ⚠️  Les _ titre / notes / preset / dueDate seront vraiment fixés dans .onAppear
    }

    // MARK: – Vue
    var body: some View {
        NavigationStack {
            Form {
                // Titre
                Section("Title") {
                    TextField("What needs to be done?", text: $title)
                        .textInputAutocapitalization(.sentences)
                }

                // Notes
                Section("Description") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                // Preset
                Section {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(TaskInputPreset.allCases, id: \ .self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Date (visible uniquement pour .plan)
                Section("Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .disabled(selectedPreset != .plan)
                        .opacity(selectedPreset == .plan ? 1.0 : 0.4)
                }
            }
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(task == nil ? "Create" : "Save") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
            }
            .onAppear {
                populateIfEditing()
                handlePresetChange() // fixe l’état initial des dates
            }
            .onChange(of: selectedPreset) { _ in
                handlePresetChange()
            }
        }
    }

    // MARK: – Préremplissage pour l’édition
    private func populateIfEditing() {
        guard let t = task else { return }
        title = t.title
        notes = t.notes ?? ""
        selectedPreset = preset(for: t)
        // dueDate sera ajustée par handlePresetChange()
        if let d = t.dueDate { dueDate = d }
    }

    private func preset(for task: Task) -> TaskInputPreset {
        switch task.category {
        case .inbox:  return .inbox
        case .later:  return .later
        case .planned:
            if let d = task.dueDate, Calendar.current.isDateInToday(d) {
                return .today
            } else {
                return .plan
            }
        default:
            return .inbox
        }
    }

    // MARK: – Gestion Preset ➜ date
    private func handlePresetChange() {
        switch selectedPreset {
        case .today:
            dueDate = .now
        case .plan:
            // Si la date est passée ou aujourd’hui ➜ +1 jour
            if Calendar.current.isDateInToday(dueDate) || dueDate < Date() {
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
            }
        default:
            // Inbox & Later n’utilisent pas la date
            break
        }
    }

    // MARK: – Enregistrement
    private func save() {
        if let existing = task {
            update(existing)
        } else {
            createTask()
        }
        try? context.save()
        dismiss()
    }

    private func createTask() {
        let (category, date) = mappingFromPreset()
        let newTask = Task(title: title,
                           notes: notes.isEmpty ? nil : notes,
                           category: category,
                           dueDate: date)
        context.insert(newTask)
    }

    private func update(_ task: Task) {
        let (category, date) = mappingFromPreset()
        task.title    = title
        task.notes    = notes.isEmpty ? nil : notes
        task.category = category
        task.dueDate  = date
    }

    private func mappingFromPreset() -> (TaskCategory, Date?) {
        switch selectedPreset {
        case .inbox:
            return (.inbox, nil)
        case .today:
            return (.planned, Date())
        case .plan:
            return (.planned, dueDate)
        case .later:
            return (.later, nil)
        }
    }
}

// MARK: – Support
extension TaskCategory: Identifiable {
    public var id: Self { self }
}
