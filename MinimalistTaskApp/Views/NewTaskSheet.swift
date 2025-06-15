import SwiftUI
import SwiftData

enum TaskInputPreset: String, CaseIterable {
    case inbox = "Inbox"
    case today = "Today"
    case plan  = "Plan"
    case later = "Later"
}

struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedPreset: TaskInputPreset
    @State private var dueDate: Date = Date()

    init(defaultSelection: TaskInputPreset = .inbox) {
        _selectedPreset = State(initialValue: defaultSelection)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("What needs to be done?", text: $title)
                }
                Section("Description") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                Section {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(TaskInputPreset.allCases, id: \.self) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("Date") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                        .disabled(selectedPreset != .plan)
                        .opacity(selectedPreset == .plan ? 1.0 : 0.4)
                }
            }
            .onChange(of: selectedPreset) { _ in
                handlePresetChange()
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                handlePresetChange()
            }
        }
    }

    private func handlePresetChange() {
        switch selectedPreset {
        case .today:
            dueDate = Date()
        case .plan:
            if Calendar.current.isDateInToday(dueDate) || dueDate < Date() {
                dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            }
        default:
            // inbox & later don't use date
            break
        }
    }

    private func createTask() {
        let category: TaskCategory
        let date: Date?

        switch selectedPreset {
        case .inbox:
            category = .inbox
            date = nil
        case .today:
            category = .planned
            date = Date()
        case .plan:
            category = .planned
            date = dueDate
        case .later:
            category = .later
            date = nil
        }

        let newTask = Task(title: title,
                           notes: notes.isEmpty ? nil : notes,
                           category: category,
                           dueDate: date)
        context.insert(newTask)
        dismiss()
    }
}
