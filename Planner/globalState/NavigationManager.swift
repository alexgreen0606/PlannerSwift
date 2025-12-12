//
//  NavigationManager.swift
//  Planner
//
//  Created by Alex Green on 12/8/25.
//

import SwiftUI

@Observable
class NavigationManager {
    static let shared = NavigationManager()
    private init() {}
    
    // This can be set to open a new planner.
    // TODO: ensure the planner tab is opened when this changes
    var selectedPlannerDate: Date = Date() // TODO: why store this here? Can I store the date in the navigation path?
    
    var plannerPath = NavigationPath()
}
