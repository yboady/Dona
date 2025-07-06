import SwiftUI
import SwiftData

/// Vue « All Tasks »
/// Affiche toutes les tâches, avec recherche et filtre.
struct TaskListAllView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]

    @State private var editingTask: Task?
    @State private var searchText: String = ""
    @State private var selectedFilter: TaskFilter = .all

    private enum TaskFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case done = "Done"
        case notDone = "Not Done"
        var id: String { rawValue }
    }

    private var filteredTasks: [Task] {
        allTasks.filter { task in
            // Recherche par titre
            let matchesSearch = searchText.isEmpty || task.title.localizedCaseInsensitiveContains(searchText)
            // Filtre par statut
            let matchesFilter: Bool = {
                switch selectedFilter {
                case .all:     return true
                case .done:    return task.category == .done
                case .notDone: return task.category != .done
                }
            }()
            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Search") {
                    TextField("Search tasks", text: $searchText)
                        .textInputAutocapitalization(.none)
                }
                Section("Filter") {
                    Picker("Status", selection: $selectedFilter) {
                        ForEach(TaskFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .padding(.vertical, 4)
                    .pickerStyle(.segmented)
                }
                Section("All Tasks (\(filteredTasks.count))") {
                    ForEach(filteredTasks) { task in
                        TaskRowView(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { editingTask = task }
                    }
                    .onDelete(perform: deleteTasks)
                }
            }
            .padding(.top, 16)
            .navigationTitle("All Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Text("All Tasks")
                            .font(.title3).bold()
                        Text("\(filteredTasks.count)")
                            .font(.subheadline).bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .sheet(item: $editingTask) { task in
                TaskSheet(task: task)
            }
        }
    }

    private func deleteTasks(at offsets: IndexSet) {
        offsets
            .map { filteredTasks[$0] }
            .forEach(context.delete)
        try? context.save()
    }
}

#Preview {
    TaskListAllView().modelContainer(for: Task.self, inMemory: true)
}
