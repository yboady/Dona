// TaskListInboxView.swift
// Basé sur le contenu original de TaskListInboxView.swift :contentReference[oaicite:1]{index=1}

import SwiftUI
import SwiftData

/// Vue « Inbox »
/// Affiche :
///   • Les tâches en New (Inbox)
///   • Les tâches snoozées 1–3 fois
///   • Les tâches snoozées plus de 3 fois
///   • Un message de félicitations si tout est vide.
struct TaskListInboxView: View {
    // MARK: – Données
    @Query(sort: [SortDescriptor(\Task.createdAt, order: .reverse)])
    private var allTasks: [Task]
    @Environment(\.modelContext) private var context

    // MARK: – État
    @State private var showingNew = false
    @State private var editingTask: Task?

    // MARK: – Filtrage
    /// Tâches new (inbox)
    private var inboxTasks: [Task] {
        context.unsnoozeIfNeeded()
        return allTasks.filter {
            $0.category == .inbox
            && ($0.countSnoozes == nil || $0.countSnoozes! == 0)
        }
    }
    /// Tâches snoozées 1 à 3 fois
    private var snoozedOnceTasks: [Task] {
        allTasks.filter {
            $0.category == .inbox
            && $0.countSnoozes != nil
            && $0.countSnoozes! > 0
            && $0.countSnoozes! <= 3
        }
    }
    /// Tâches snoozées plus de 3 fois
    private var snoozedMoreThan3Tasks: [Task] {
        allTasks.filter {
            $0.category == .inbox
            && $0.countSnoozes != nil
            && $0.countSnoozes! > 3
        }
    }

    // MARK: – View
    var body: some View {
        NavigationStack {
            List {
                // — New
                if !inboxTasks.isEmpty {
                    Section(header: Text("New (\(inboxTasks.count))")) {
                        ForEach(inboxTasks) { task in
                            TaskRowView(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                        }
                        .onDelete(perform: deleteInbox)
                    }
                }

                // — Snoozed 1–3 times
                if !snoozedOnceTasks.isEmpty {
                    Section(header: Text("Snoozed (\(snoozedOnceTasks.count))")) {
                        ForEach(snoozedOnceTasks) { task in
                            TaskRowView(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                        }
                        .onDelete { offsets in
                            offsets.map { snoozedOnceTasks[$0] }
                                .forEach(context.delete)
                            try? context.save()
                        }
                    }
                }

                // — Snoozed more than 3 times
                if !snoozedMoreThan3Tasks.isEmpty {
                    Section(header: Text("Snoozed more than 3 times (\(snoozedMoreThan3Tasks.count))")) {
                        ForEach(snoozedMoreThan3Tasks) { task in
                            TaskRowView(task: task)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTask = task }
                        }
                        .onDelete { offsets in
                            offsets.map { snoozedMoreThan3Tasks[$0] }
                                .forEach(context.delete)
                            try? context.save()
                        }
                    }
                }

                // — Félicitations si tout est vide
                if inboxTasks.isEmpty
                    && snoozedOnceTasks.isEmpty
                    && snoozedMoreThan3Tasks.isEmpty
                {
                    Section {
                        VStack(spacing: 12) {
                            ZStack {
                                Image(systemName: "tray.fill")
                                    .font(.system(size: 42))
                                    .foregroundColor(CategoryColor.inbox)
                            }
                            Text("Congratulations, you've cleared your inbox! 🎉")
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
            .navigationTitle("Inbox")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 10) {
                        Text("Inbox")
                            .font(.title3).bold()
                        Text("\(inboxTasks.count)")
                            .font(.subheadline).bold()
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(CategoryColor.inbox)
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            context.unsnoozeIfNeeded()
        }
        .sheet(isPresented: $showingNew) { TaskSheet(task: nil) }
        .sheet(item: $editingTask) { TaskSheet(task: $0) }
    }

    // MARK: – Actions de suppression
    private func deleteInbox(at offsets: IndexSet) {
        offsets.map { inboxTasks[$0] }.forEach(context.delete)
        try? context.save()
    }
}
