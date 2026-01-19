//
//  CalendarSettings.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import SwiftData

@Model
class CalendarSettings {

    // Maps Calendar events IDs to system image names.
    var iconMap: [String: String] = [:]

    // Set of calendar IDs to exclude from planners.
    var hiddenCalendarIds: Set<String> = []

    // Maps Calendar events IDs to sortIndex values for their planner references.
    var sortIndexMap: [String: Double] = [:]
    
    // Set of event IDs that have been checked within their planner.
    var checkedCalendarEventIds: Set<String> = []

    init() {}
}
