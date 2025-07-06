import SwiftUI
import SwiftData

struct TaskListLaterView: View {
    @Environment(\.modelContext) private var context

    // ⬇️ Toutes les tâches, non filtrées
    @Query(sort: [SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]

    @State private var showingNew = false
    @State private var editingTask: Task?

    // MARK: – Préparation des données -----------------------------------------

    /// Tâches encore *vraiment* en Later (on écarte celles dont la date est expirée)
    private var activeLater: [Task] {
        allTasks.filter { task in
            task.category == .later &&
            !(task.snoozedUntil != nil && task.snoozedUntil! <= Date())
        }
    }
    
    private var totalLater: Int {
        activeLater.count
    }

    /// Tableau ordonné de sections : (label, tâches)
    private var grouped: [(String, [Task])] {
        let cal = Calendar.current

        // --- 1. Someday en premier -------------------------------------------
        var sections: [(String, [Task])] = []
        let somedayTasks = activeLater.filter { $0.snoozedUntil == nil }
                                      .sorted { $0.createdAt < $1.createdAt }
        if !somedayTasks.isEmpty {
            sections.append(("Someday", somedayTasks))
        }

        // --- 2. Regroupement par jour pour les tâches datées -----------------
        let dated = activeLater.compactMap { t -> (Date, Task)? in
            guard let d = t.snoozedUntil else { return nil }
            return (cal.startOfDay(for: d), t)
        }

        // Dictionary<Date, [Task]>
        var byDay: [Date: [Task]] = [:]
        for (day, task) in dated { byDay[day, default: []].append(task) }

        // Tri des dates, puis tri interne des tâches
        let formatter = RelativeDateTimeFormatter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE d MMM yyyy"

        let sortedDays = byDay.keys.sorted()
        for day in sortedDays {
            let label: String
            if cal.isDateInToday(day) || cal.isDateInTomorrow(day) ||
               cal.isDateInYesterday(day) {
                label = formatter.localizedString(for: day, relativeTo: Date())
            } else {
                label = dateFormatter.string(from: day)
            }

            let tasks = byDay[day]!.sorted { ($0.snoozedUntil ?? Date.distantFuture) <
                                             ($1.snoozedUntil ?? Date.distantFuture) }
            sections.append((label, tasks))
        }

        return sections
    }

    // MARK: – Vue --------------------------------------------------------------

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.0) { section in
                    Section(section.0) {
                        ForEach(section.1) { task in
                            TaskRowView(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                        }
                        .onDelete { offsets in delete(offsets, in: section.1) }
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
            .navigationTitle("Later")
            .navigationBarTitleDisplayMode(.inline)
            // Effet glass permanent
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Text("Later")
                            .font(.title3)
                            .bold()
                        Text("\(totalLater)")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(CategoryColor.later)
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .sheet(isPresented: $showingNew)   { TaskSheet(task: nil, defaultPreset: .later) }
            .sheet(item: $editingTask) { task in TaskSheet(task: task) }
        }
    }

    // MARK: – Suppression ------------------------------------------------------

    private func delete(_ offsets: IndexSet, in tasks: [Task]) {
        for index in offsets { context.delete(tasks[index]) }
    }
}
