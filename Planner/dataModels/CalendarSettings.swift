//
//  PlannerSettings.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import SwiftData

@Model
class PlannerSettings {

    // Maps Calendar events IDs to system image names.
    var iconMap: [String: String] = [:]

    // Maps Calendar events IDs to sortIndex values for their planner references.
    var sortIndexMap: [String: Double] = [:]
    
    // Set of calendar IDs to exclude from planners.
    var hiddenCalendarIds: Set<String> = []
    
    // Set of calendarItemExternalIdentifiers that have been checked within their planner.
    var checkedCalendarEventIds: Set<String> = []
    
    var homeLocation: Location?

    init() {}
}
