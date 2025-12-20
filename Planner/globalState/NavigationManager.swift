//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 12/8/25.
//

import SwiftUI

enum AppTab: Hashable {
    case recurring, checklists, search
}

@Observable
class NavigationManager {
    static let shared = NavigationManager()
    private init() {}
    
    var selectedTab: AppTab = .search
    
    var isPlannerOpen: Bool = false
    var plannerDatestamp: String = ""
    
    var selectedPlannerDate: Date = Date() // TODO: why store this here? Can I store the date in the navigation path?
    
    var plannerPath = NavigationPath()
    var checklistsPath = NavigationPath()
}
