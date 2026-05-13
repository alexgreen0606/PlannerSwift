//
//  ChecklistItemColor.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftUI

// Clean

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

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .cyan: return .cyan
        case .indigo: return .indigo
        case .purple: return .purple
        case .brown: return .brown
        case .label: return Color.label
        }
    }
}
