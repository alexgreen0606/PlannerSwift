//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 12/8/25.
//

import SwiftUI
import Combine

enum AppTab: Hashable {
    case routines, checklists, search
}

@MainActor
class NavigationManager: ObservableObject {
    @Published var selectedTab: AppTab = .search
    @Published var checklistsPath = NavigationPath()
    @Published var plannerPath = NavigationPath()
}
