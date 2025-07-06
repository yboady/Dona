import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: – Onglets
enum TaskTab: Hashable { case inbox, today, plan, later }

struct ContentView: View {
    // ENVIRONNEMENT
    @Environment(\.modelContext) private var context

    // ÉTATS
    @State private var tab: TaskTab = .inbox           // onglet actif
    @State private var showingNew  = false             // feuille création
    @State private var showingAll = false              // feuille All Tasks
    @State private var editingTask: Task? = nil        // feuille édition (Plan)
    @State private var hoverTab: TaskTab? = nil        // survol drag‑and‑drop
    
    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.4))
            .frame(width: 1, height: 32)
    }

    var body: some View {
        ZStack {
            // ======================= CONTENU PRINCIPAL =======================
            TabView(selection: $tab) {
                TaskListInboxView() .tag(TaskTab.inbox)
                TaskListTodayView() .tag(TaskTab.today)
                TaskListPlanView()  .tag(TaskTab.plan)
                TaskListLaterView() .tag(TaskTab.later)
            }
            .toolbar(.hidden, for: .tabBar)            // on masque la TabBar Apple
        }
        // ======================= BARRE PERSO EN BAS =========================
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // Ligne d’onglets (dépose possible)
                HStack(spacing: 0) {
                    tabButton(.inbox, symbol: "tray")
                    divider
                    tabButton(.today, symbol: "checkmark.square")
                    divider
                    tabButton(.plan,  symbol: "calendar")
                    divider
                    tabButton(.later, symbol: "clock")
                }
                .padding(.vertical, 18)   // ↕️ hauteur accrue

                Divider()

                // Boutons « Add Task » et « All Tasks »
                HStack(spacing: 16) {
                    Button {
                        showingAll = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                            .padding(.vertical, 24)
                    }
                    .accessibilityLabel("All tasks")
                    Spacer()
                    Button { showingNew = true } label: {
                        Label("Add Task", systemImage: "plus.circle.fill")
                            .font(.title2)                      // icône un peu plus grande
                            .foregroundColor(presetForCurrentTab.color)
                            .padding(.vertical, 24)
                    }
                    .accessibilityLabel("Add task")
                    Spacer()
                    Button {
                        print("Settings")
                    } label: {
                        Image(systemName: "gear")
                            .font(.title2)
                            .foregroundColor(.clear)
                            .padding(.vertical, 24)
                    }
                    .accessibilityLabel("Settings")
                    
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .background(.ultraThinMaterial)                // fond translucide natif
        }
        // ======================= FEUILLES =========================
        .sheet(isPresented: $showingNew) {
            TaskSheet(defaultPreset: presetForCurrentTab)
        }
        .sheet(item: $editingTask) { task in           // ouvrira sur Plan
            TaskSheet(task: task, defaultPreset: .plan)
        }
        .sheet(isPresented: $showingAll) {
            TaskListAllView()
        }
    }

    // MARK: – Bouton d’onglet + destination de drop + survol visuel
    @ViewBuilder
    private func tabButton(_ target: TaskTab, symbol: String) -> some View {
        let isActive   = tab == target
        let isHovering = hoverTab == target

        Button { tab = target } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? filledSymbol(symbol) : symbol)
                    .font(.system(size: 24))  // ↗️ icône légèrement plus grande
                Text(title(for: target))
                    .font(.caption2)
            }
            .foregroundColor(isActive ? Color.white : .secondary)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive
                          ? target.color      // halo bleu clair
                          : (isHovering ? Color.gray.opacity(0.2)
                                        : .clear))
            )
        }
        .accessibilityLabel("Switch to \(title(for: target))")
        // —— Destination Drag‑and‑Drop ——
        .dropDestination(for: Task.self, action: { tasks, _ in
            handleDrop(tasks: tasks, to: target)
            return true
        }, isTargeted: { hovering in
            if hovering {
                hoverTab = target
            } else if hoverTab == target {
                hoverTab = nil
            }
        })
    }

    /// Binding<Bool> qui reflète le survol
    private func binding(for target: TaskTab) -> Binding<Bool> {
        Binding(
            get: { hoverTab == target },
            set: { hovering in
                if hovering {
                    hoverTab = target
                } else if hoverTab == target {
                    hoverTab = nil
                }
            }
        )
    }

    // MARK: – Gestion du drop
    private func handleDrop(tasks: [Task], to target: TaskTab) {
        guard let dropped = tasks.first,
              let original = try? taskInContext(with: dropped.id) else { return }

        switch target {
        case .inbox:
            original.category = .inbox
            original.dueDate  = nil
        case .later:
            original.category = .later
            original.dueDate  = nil
        case .today:
            original.category = .planned
            original.dueDate  = Calendar.current.startOfDay(for: Date())
        case .plan:
            original.category = .planned
            if original.dueDate == nil {
                original.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
            }
            try? context.save()
            editingTask = original
            return
        }
        try? context.save()
    }

    /// Cherche la tâche réelle (gérée par SwiftData) via son UUID
    private func taskInContext(with id: UUID) throws -> Task? {
        var descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: – Helpers (icônes et libellés)
    private func filledSymbol(_ base: String) -> String {
        let candidate = base + ".fill"
        return UIImage(systemName: candidate) != nil ? candidate : base
    }

    private func title(for tab: TaskTab) -> String {
        switch tab {
        case .inbox: "Inbox"
        case .today: "Today"
        case .plan:  "Plan"
        case .later: "Later"
        }
    }

    // Onglet ➜ preset par défaut
    private var presetForCurrentTab: TaskInputPreset {
        switch tab {
        case .inbox: .inbox
        case .today: .today
        case .plan:  .plan
        case .later: .later
        }
    }
}

// MARK: – Drag support pour Task
extension Task: Transferable {
    public static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskItem)
    }
}

// Déclare un UTType perso pour la tâche
extension UTType {
    static let taskItem = UTType(exportedAs: "com.dona.task")
}

#Preview {
    ContentView().modelContainer(for: Task.self, inMemory: true)
}
