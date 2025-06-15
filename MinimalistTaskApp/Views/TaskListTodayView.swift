import SwiftUI
import SwiftData

struct TaskListTodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var plannedTasks: [Task]
    @State private var showingNew = false

    init() {
        _plannedTasks = Query(filter: #Predicate<Task> { task in
            task.category == TaskCategory.planned && task.dueDate != nil
        }, sort: [SortDescriptor(\Task.dueDate, order: .forward)])
    }

    private var todayTasks: [Task] {
        plannedTasks.filter { task in
            guard let date = task.dueDate else { return false }
            return Calendar.current.isDateInToday(date)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(todayTasks) { task in
                    TaskRowView(task: task)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingNew.toggle() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NewTaskSheet(defaultSelection: .today)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(todayTasks[index])
        }
    }
}
