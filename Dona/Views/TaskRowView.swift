import SwiftUI

struct TaskRowView: View {
    @Bindable var task: Task

    var body: some View {
        HStack {
            Image(systemName: task.category == .done ? "checkmark.circle.fill" : "circle")
                .onTapGesture {
                    withAnimation {
                        task.category = task.category == .done ? .inbox : .done
                    }
                }
            VStack(alignment: .leading) {
                Text(task.title)
                    .strikethrough(task.category == .done)
                    .foregroundStyle(task.category == .done ? .secondary : .primary)
                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let due = task.dueDate {
                Text(due, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
