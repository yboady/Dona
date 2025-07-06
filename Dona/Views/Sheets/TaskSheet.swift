import SwiftUI
import SwiftData

/// Formulaire unique pour créer **ou** modifier une tâche.
/// - Passez `task == nil` pour créer.
/// - Passez une `Task` existante pour éditer.
struct TaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    // ───────── Paramètres ─────────
    let task: Task?
    let defaultPreset: TaskInputPreset

    // ───────── États généraux ─────────
    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var selectedPreset: TaskInputPreset
    @State private var dueDate: Date = .now

    // Autofocus sur le titre en création
    @FocusState private var isTitleFocused: Bool

    // ───────── Snooze ─────────
    private enum SnoozeMode { case relative, chooseDate, someday }
    private enum RelativeSnooze: CaseIterable {
        case tomorrow, nextWeekend, nextMonth
        var label: String {
            switch self {
            case .tomorrow:     "Tomorrow"
            case .nextWeekend:  "Next Weekend"
            case .nextMonth:    "Next Month"
            }
        }
        func date(from base: Date) -> Date {
                let cal = Calendar.current
                switch self {
                case .tomorrow:
                    return cal.date(byAdding: .day, value: 1, to: base)!
                case .nextWeekend:
                    return cal.nextWeekend(startingAfter: base)?.start
                        ?? cal.date(byAdding: .day, value: 7, to: base)!
                case .nextMonth:
                    // 1er du mois suivant à 00 h 00
                    var comp = cal.dateComponents([.year, .month], from: base)
                    comp.month! += 1
                    comp.day = 1
                    return cal.date(from: comp)!
                }
            }
    }

    @State private var snoozeMode: SnoozeMode = .relative
    @State private var relativeChoice: RelativeSnooze = .tomorrow
    @State private var customDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
    @State private var snoozedUntil: Date? = nil     // ← persistant dans Task

    // ───────── Init ─────────
    init(task: Task? = nil, defaultPreset: TaskInputPreset = .inbox) {
        self.task = task
        self.defaultPreset = defaultPreset
        _selectedPreset = State(initialValue: defaultPreset)
    }

    // ───────── Vue ─────────
    var body: some View {
        NavigationStack {
            Form {
                // ---- Title ----
                Section("Title") {
                    TextField("What needs to be done?", text: $title)
                        .textInputAutocapitalization(.sentences)
                        .focused($isTitleFocused)
                }

                // ---- Description ----
                Section("Description") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60) // hauteur réduite (une ligne en moins)
                }

                // ---- Category ----
                Section("Category") { categoryPicker }

                // ---- Due date ----
                switch selectedPreset {
                case .plan:
                    Section("Date") {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.graphical) // Calendrier graphique pour Plan
                    }
                case .today:
                    Section("Date") {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
                            .disabled(true) // Non modifiable pour Today
                    }
                default:
                    EmptyView()
                }

                // ---- Snooze / Later ----
                if selectedPreset == .later { laterSection }
            }
            // Réduction des espacements entre lignes/sections
            .listSectionSpacing(8)
            .environment(\.defaultMinListRowHeight, 40)
            .navigationTitle(task == nil ? "New Task" : "Edit Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(task == nil ? "Create" : "Save") { save() }
                        .foregroundColor(.white)
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                populateIfEditing()
                // Autofocus uniquement en création
                if task == nil {
                    // Délai minimal pour laisser la feuille se présenter avant de demander le focus
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTitleFocused = true
                    }
                }
            }
        }
    }

    // MARK: – Sections UI -------------------------------------------------------

    private var categoryPicker: some View {
        HStack(spacing: 0) {
            ForEach(Array(TaskInputPreset.allCases.enumerated()), id: \.1) { idx, preset in
                Button { selectedPreset = preset } label: {
                    VStack(spacing: 6) { // spacing réduit
                        Image(systemName: iconName(for: preset,
                                                   isSelected: preset == selectedPreset))
                            .font(.title3)
                        Text(preset.rawValue).font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .foregroundStyle(preset == selectedPreset ? preset.color : .secondary)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(preset == selectedPreset ? preset.color.lighter(by: 0.8) : .clear)
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                if idx < TaskInputPreset.allCases.count - 1 {
                    Rectangle().fill(.gray.opacity(0.4))
                        .frame(width: 1, height: 28)
                }
            }
        }
    }

    private var laterSection: some View {
        Section("Later") {

            // ---------- Relative ----------
            Text("Relative")
                .font(.footnote)
                .foregroundColor(.secondary)
            ForEach(RelativeSnooze.allCases, id: \.self) { opt in
                checkRow(opt.label,
                         isOn: snoozeMode == .relative && relativeChoice == opt) {
                    snoozeMode = .relative
                    relativeChoice = opt
                }
            }

            // ---------- Choose Date ----------
            checkRow("Choose Date", isOn: snoozeMode == .chooseDate) {
                snoozeMode = .chooseDate
            }
            if snoozeMode == .chooseDate {
                DatePicker("Return Date",
                           selection: $customDate,
                           displayedComponents: .date)
                    .datePickerStyle(.graphical)
            }

            // ---------- Someday ----------
            checkRow("Someday", isOn: snoozeMode == .someday) {
                snoozeMode = .someday
            }
        }
    }

    private func checkRow(_ label: String,
                          isOn: Bool,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                Spacer()
                if isOn { Image(systemName: "checkmark") }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: – Édition et persistance -------------------------------------------

    private func populateIfEditing() {
        guard let t = task else { return }
        title = t.title
        notes = t.notes ?? ""
        selectedPreset = preset(for: t)
        if let d = t.dueDate { dueDate = d }

        // Préselection Snooze
        if selectedPreset == .later {
            if let d = t.snoozedUntil {
                snoozeMode = .chooseDate
                customDate = d
            } else {
                snoozeMode = .someday
            }
        }
    }

    private func preset(for task: Task) -> TaskInputPreset {
        switch task.category {
        case .inbox: .inbox
        case .later: .later
        case .planned:
            if let d = task.dueDate, Calendar.current.isDateInToday(d) { .today } else { .plan }
        case .done: .inbox
        }
    }

    private func save() {
        computeSnoozedUntil()

        if let existing = task { update(existing) } else { createTask() }
        try? context.save()
        dismiss()
    }

    /// Calcule la date de retour selon le mode courant.
    private func computeSnoozedUntil() {
        guard selectedPreset == .later else { snoozedUntil = nil; return }

        switch snoozeMode {
        case .someday:
            snoozedUntil = nil
        case .chooseDate:
            snoozedUntil = customDate
        case .relative:
            snoozedUntil = relativeChoice.date(from: .now)
        }
    }

    private func createTask() {
        let (cat, date) = mappingFromPreset()
        let new = Task(title: title,
                       notes: notes.isEmpty ? nil : notes,
                       category: cat,
                       dueDate: date)
        context.insert(new)
        new.snoozedUntil = snoozedUntil
    }

    private func update(_ task: Task) {
        let (cat, date) = mappingFromPreset()
        task.title = title
        task.notes = notes.isEmpty ? nil : notes
        task.category = cat
        task.dueDate = date
        task.snoozedUntil = snoozedUntil
    }

    private func mappingFromPreset() -> (TaskCategory, Date?) {
        switch selectedPreset {
        case .inbox: (.inbox, nil)
        case .today: (.planned, .now)
        case .plan:  (.planned, dueDate)
        case .later: (.later, nil)
        }
    }

    // MARK: – Icon helper -------------------------------------------------------

    private func iconName(for preset: TaskInputPreset, isSelected: Bool) -> String {
        let base: String
        switch preset {
        case .inbox: base = "tray"
        case .today: base = "checkmark.square"
        case .plan:  base = "calendar"
        case .later: base = "clock"
        }
        let filled = base + ".fill"
        return isSelected && UIImage(systemName: filled) != nil ? filled : base
    }
}
