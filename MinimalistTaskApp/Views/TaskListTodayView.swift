import SwiftUI
import SwiftData

struct TaskListTodayView: View {
    @Environment(\.modelContext) private var context
    // ⬇️  plus aucun filtre sur l’enum dans le #Predicate
    @Query(sort: [SortDescriptor(\Task.dueDate, order: .forward)])
    private var allTasks: [Task]

    @State private var showingNew = false

    /// Tâches .planned dont la date est « aujourd’hui »
    private var todayTasks: [Task] {
        allTasks.filter { task in
            guard task.category == .planned,           // filtrage en mémoire
                  let date = task.dueDate else { return false }
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
        for index in offsets { context.delete(todayTasks[index]) }
    }
}
