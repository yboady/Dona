import SwiftUI
import SwiftData

struct TaskListLaterView: View {
    @Environment(\.modelContext) private var context

    // ⬇️ récupère toutes les tâches, non filtrées
    @Query(sort: [SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]

    @State private var showingNew = false
    @State private var editingTask: Task?

    /// Filtrage en mémoire : seulement les tâches .later
    private var laterTasks: [Task] {
        allTasks.filter { $0.category == .later }
    }

    var body: some View {
        NavigationStack {
                            List {
                                ForEach(laterTasks) { task in
                                    TaskRowView(task: task)
                                        .contentShape(Rectangle())
                                        .onTapGesture { editingTask = task }
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
                                TaskSheet(task: nil)
                            }
                            .sheet(item: $editingTask) { task in
                                TaskSheet(task: task)
                            }
                        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            context.delete(laterTasks[index])
        }
    }
}
