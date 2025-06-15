import SwiftUI
import SwiftData

struct TaskListPlanView: View {
    @Environment(\.modelContext) private var context
    // Pas de filtre sur l’enum : on récupère juste les tâches datées
    @Query(filter: #Predicate<Task> { task in
        task.dueDate != nil            // évite les nil dans le groupement
    },
    sort: [SortDescriptor(\Task.dueDate, order: .forward)])
    private var datedTasks: [Task]

    @State private var showingNew = false

    /// Tâches .planned datées strictement après aujourd’hui
    private var futurePlanned: [Task] {
        let tomorrow = Calendar.current.date(
            byAdding: .day,
            value: 1,
            to: Calendar.current.startOfDay(for: Date())
        )!
        return datedTasks.filter { task in
            task.category == .planned && (task.dueDate ?? Date()) >= tomorrow
        }
    }

    /// Regroupe par jour pour afficher des sections
    private var grouped: [(date: Date, tasks: [Task])] {
        let dict = Dictionary(grouping: futurePlanned) { task in
            Calendar.current.startOfDay(for: task.dueDate ?? Date())
        }
        return dict.keys.sorted().map { (date: $0, tasks: dict[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.date) { group in
                    Section(header: Text(group.date, style: .date)) {
                        ForEach(group.tasks) { task in
                            TaskRowView(task: task)
                        }
                        .onDelete { offsets in
                            delete(offsets, in: group.tasks)
                        }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingNew.toggle() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NewTaskSheet(defaultSelection: .plan)
            }
        }
    }

    private func delete(_ offsets: IndexSet, in tasks: [Task]) {
        for index in offsets { context.delete(tasks[index]) }
    }
}
