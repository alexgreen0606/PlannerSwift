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

// TODO: move elsewhere
enum CalendarEventEditConfig: Identifiable {
    case edit(EKEvent)
    case view(EKEvent)

    var id: String {
        switch self {
        case .edit(let event):
            String(describing: event.eventIdentifier)
        case .view(let event):
            String(describing: event.eventIdentifier)
        }
    }
}

@Observable
class NavigationManager {
    static let shared = NavigationManager()
    private init() {}
    
    var selectedTab: AppTab = .search
    
    var selectedPlannerDate: Date = Date() // TODO: why store this here? Can I store the date in the navigation path?
    
    var checklistsPath = NavigationPath()
}
