import Foundation
import SwiftData

@Model
class Task: Identifiable {
    var id: UUID
    var title: String
    var notes: String?
    var category: TaskCategory
    var dueDate: Date?
    var createdAt: Date

    init(title: String,
         notes: String? = nil,
         category: TaskCategory = .inbox,
         dueDate: Date? = nil,
         createdAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.category = category
        self.dueDate = dueDate
        self.createdAt = createdAt
    }
}

enum TaskCategory: String, Codable, CaseIterable {
    case inbox
    case planned
    case later
    case done
}

extension TaskCategory {
    var localizedTitle: String {
        switch self {
        case .inbox: return "Inbox"
        case .planned:  return "Planned"
        case .later: return "Later"
        case .done: return "Done"
        }
    }

    var tabIcon: String {
        switch self {
        case .inbox: return "tray"
        case .planned:  return "calendar"
        case .later: return "clock"
        case .done: return "checkmark.circle"
        }
    }
}
