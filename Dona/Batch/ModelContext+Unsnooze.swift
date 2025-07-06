// ModelContext+Unsnooze.swift
// Dona – Snooze / Later
// Patch #5 (2025-06-17)
//
// Eliminates the enum‑case predicate entirely to bypass the error
// « Key path cannot refer to enum case 'later' ». We simply fetch all
// tasks and do the filtering in-memory; for a normal‑sized personal
// to‑do list this has no perceptible cost.

import Foundation
import SwiftData

extension ModelContext {
  func unsnoozeIfNeeded() {
    let desc = FetchDescriptor<Task>()
    guard let allTasks = try? fetch(desc) else { return }

    let todayStart = Calendar.current.startOfDay(for: Date())

    for task in allTasks {
      // On sort tout de suite si la tâche n’est pas snoozée ou n’a pas de date
      guard
        task.category == .later,
        let snoozeDate = task.snoozedUntil
      else {
        continue
      }

      let snoozeStart = Calendar.current.startOfDay(for: snoozeDate)
      if snoozeStart <= todayStart {
        task.countSnoozes! += 1
        task.category     = .inbox
        task.snoozedUntil = nil
      }
    }

    try? save()
  }
}
