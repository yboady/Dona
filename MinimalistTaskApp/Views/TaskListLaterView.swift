import SwiftUI
import SwiftData

struct TaskListLaterView: View {
    @Environment(\.modelContext) private var context
    @Query private var tasks: [Task]
    @State private var showingNew = false

    init() {
        _tasks = Query(filter: #Predicate<Task> { task in
            task.category == TaskCategory.later
        }, sort: [SortDescriptor(\Task.createdAt, order: .reverse)])
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(tasks) { task in
                    TaskRowView(task: task)
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("Later")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingNew.toggle() } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                NewTaskSheet(defaultSelection: .later)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(tasks[index])
        }
    }
}
