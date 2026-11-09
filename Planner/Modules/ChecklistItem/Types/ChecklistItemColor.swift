//
//  ChecklistItemColor.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftUI

enum ChecklistItemColor: String, Codable, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case cyan
    case indigo
    case purple
    case brown
    case label
    case accent

    func swiftUIColor(accentColor: AccentColor) -> Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .cyan: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .brown: return .brown
        case .label: return Color.label
        case .accent: return accentColor.swiftUiColor
        }
    }
}
