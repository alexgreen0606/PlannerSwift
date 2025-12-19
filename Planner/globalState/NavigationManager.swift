//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 12/8/25.
//

import SwiftUI

enum AppTab: Hashable {
    case recurring, planner, checklists
}

@Observable
class NavigationManager {
    static let shared = NavigationManager()
    private init() {}
    
    var selectedTab: AppTab = .planner
    
    var selectedPlannerDate: Date = Date() // TODO: why store this here? Can I store the date in the navigation path?
    
    var plannerPath = NavigationPath()
    var checklistsPath = NavigationPath()
}
