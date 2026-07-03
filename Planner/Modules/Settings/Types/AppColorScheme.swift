//
//  AppColorScheme.swift
//  Planner
//
//  Created by Alex Green on 1/22/26.
//

import SwiftUI

enum AppColorScheme: String, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
