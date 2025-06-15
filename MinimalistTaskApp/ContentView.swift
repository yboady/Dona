import SwiftUI

enum TaskTab {
    case inbox
    case today
    case plan
    case later
}

struct ContentView: View {
    var body: some View {
        TabView {
            TaskListInboxView()
                .tabItem {
                    Label("Inbox", systemImage: TaskCategory.inbox.tabIcon)
                }
            TaskListTodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.square")
                }
            TaskListPlanView()
                .tabItem {
                    Label("Plan", systemImage: TaskCategory.planned.tabIcon)
                }
            TaskListLaterView()
                .tabItem {
                    Label("Later", systemImage: TaskCategory.later.tabIcon)
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Task.self, inMemory: true)
}
