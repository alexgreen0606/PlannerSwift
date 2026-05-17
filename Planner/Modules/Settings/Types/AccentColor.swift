//
//  AccentColor.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftUI

// Clean

enum AccentColor: String, Codable, CaseIterable {
    case red
    case pink
    case purple
    case orange
    case yellow
    case green
    case blue
    case teal
    case indigo

    static var title: String {
        "Accent Color"
    }

    var label: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        }
    }
}
