import SwiftUI
import SwiftData

struct TaskListInboxView: View {
    @Environment(\.modelContext) private var context

    // ⬇️ on récupère toutes les tâches, sans filtre côté Swift Data
    @Query(sort: [SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]

    @State private var showingNew = false
    @State private var editingTask: Task?

    /// Filtrage en mémoire : seulement les tâches .inbox
    private var inboxTasks: [Task] {
        allTasks.filter { $0.category == .inbox }
    }

    var body: some View {
        NavigationStack {
                    List {
                        ForEach(inboxTasks) { task in
                            TaskRowView(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                        }
                        .onDelete(perform: delete)
                    }
                    .navigationTitle("Inbox")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button { showingNew.toggle() } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                    .sheet(isPresented: $showingNew) {
                        TaskSheet(task: nil)
                    }
                    .sheet(item: $editingTask) { task in
                        TaskSheet(task: task)
                    }
                }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(inboxTasks[index])
        }
    }
}
