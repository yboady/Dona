import SwiftUI
import SwiftData

struct TaskListPlanView: View {
    @Environment(\.modelContext) private var context
    @Query private var plannedTasks: [Task]
    @State private var showingNew = false

    init() {
        _plannedTasks = Query(filter: #Predicate<Task> { task in
            task.category == TaskCategory.planned && task.dueDate != nil
        }, sort: [SortDescriptor(\Task.dueDate, order: .forward)])
    }

    private var futureTasks: [Task] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1,
                                             to: Calendar.current.startOfDay(for: Date()))!
        return plannedTasks.filter { task in
            guard let date = task.dueDate else { return false }
            return date >= tomorrow
        }
    }

    private var grouped: [(date: Date, tasks: [Task])] {
        let dictionary = Dictionary(grouping: futureTasks) { task in
            Calendar.current.startOfDay(for: task.dueDate ?? Date())
        }
        return dictionary.keys.sorted().map { key in
            (key, dictionary[key] ?? [])
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.date) { group in
                    Section(header: Text(group.date, style: .date)) {
                        ForEach(group.tasks) { task in
                            TaskRowView(task: task)
                        }
                        .onDelete { indexSet in
                            delete(indexSet, in: group.tasks)
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
        for index in offsets {
            context.delete(tasks[index])
        }
    }
}
