//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 12/8/25.
//

import SwiftUI
import EventKit

enum AppTab: Hashable {
    case recurring, checklists, search
}

@Observable
class NavigationManager {
    static let shared = NavigationManager()
    private init() {}
    
    var selectedTab: AppTab = .search
    
    var selectedPlannerDate: Date = Date() // TODO: why store this here? Can I store the date in the navigation path?
    
    var checklistsPath = NavigationPath()
}
