//
//  CategoryColors.swift
//  Dona
//
//  Centralised palette for task categories.
//  Edit the hex codes below to change the whole theme in one place.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Hex → Color convenience
extension Color {
    /// Initialise a Color from a 6‑digit hexadecimal string (RRGGBB).
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
                         .replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        self.init(
            red:   Double((value & 0xFF0000) >> 16) / 255,
            green: Double((value & 0x00FF00) >>  8) / 255,
            blue:  Double( value & 0x0000FF      ) / 255
        )
    }

    /// Returns a lighter variant of the colour by tweaking brightness/saturation.
    /// - parameter amount: 0 = unchanged, 1 = fully white. Default ≈ 25 %.
    func lighter(by amount: Double = 0.25) -> Color {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return Color(hue: Double(h),
                         saturation: Double(max(0, s - amount * s)),
                         brightness: Double(min(1, b + amount * (1 - b))),
                         opacity: Double(a))
        }
#endif
        return self
    }

}

// MARK: - Single source of truth
enum CategoryColor {
    static var inbox = Color(hex: "E06E97")   // 📥
    static var today = Color(hex: "6F4FCE")   // 📅
    static var plan  = Color(hex: "439EEB")   // 🗓️
    static var later = Color(hex: "16A47F")   // 💤
}

// MARK: - Convenient accessors
extension TaskTab {
    var color: Color {
        switch self {
        case .inbox: CategoryColor.inbox
        case .today: CategoryColor.today
        case .plan:  CategoryColor.plan
        case .later: CategoryColor.later
        }
    }
}

extension TaskInputPreset {
    var color: Color {
        switch self {
        case .inbox: CategoryColor.inbox
        case .today: CategoryColor.today
        case .plan:  CategoryColor.plan
        case .later: CategoryColor.later
        }
    }
}

extension TaskCategory {
    /// For use in TaskRowView & elsewhere
    var color: Color {
        switch self {
        case .inbox:   CategoryColor.inbox
        case .planned: CategoryColor.plan   // Today & Plan share .planned
        case .later:   CategoryColor.later
        case .done:    .secondary
        }
    }
}