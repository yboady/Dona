//
//  Test.swift
//  Dona
//
//  Created by Yanice Boady on 15/06/2025.
//
import Foundation

/// 4 valeurs pré-réglées que l’utilisateur peut choisir
/// (Inbox / Today / Plan / Later)
enum TaskInputPreset: String, CaseIterable, Identifiable {
    case inbox = "Inbox"
    case today = "Today"
    case plan  = "Plan"
    case later = "Later"

    /// Conformance à `Identifiable` pratique pour les `Picker`
    var id: Self { self }
}
