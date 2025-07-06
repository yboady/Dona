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
    @State private var editingTask: Task?

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
    
    private var totalPlanned: Int {
        futurePlanned.count
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(grouped, id: \.date) { group in
                    Section(header: Text(group.date, style: .date)) {
                        ForEach(group.tasks) { task in
                            TaskRowView(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                        }
                        .onDelete { offsets in
                            delete(offsets, in: group.tasks)
                        }
                    }
                }
                
                // Félicitations si aucune tâche à faire
                if totalPlanned == 0 {
                    Section {
                        VStack(spacing: 12) {
                            ZStack {
                            // Fill background at light opacity
                            Image(systemName: "calendar")
                                .font(.system(size: 50))
                                .foregroundColor(CategoryColor.plan)
                            }
                            Text("No planned tasks for now, enjoy the hollidays ! 😉")
                                .font(.headline)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
            .navigationTitle("Plan")
            .navigationBarTitleDisplayMode(.inline)
            // Effet glass permanent
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Text("Plan")
                            .font(.title3)
                            .bold()
                        Text("\(totalPlanned)")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(CategoryColor.plan)
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
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

    private func delete(_ offsets: IndexSet, in tasks: [Task]) {
        for index in offsets { context.delete(tasks[index]) }
    }
}
