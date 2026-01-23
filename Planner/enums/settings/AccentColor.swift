//
//  AccentColor.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftUI

enum AccentColor: String, Codable, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case blue
    case indigo
    case purple
    
    var title: String {
        "Accent Color"
    }

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        }
    }

    var label: String {
        rawValue.capitalized
    }
}
