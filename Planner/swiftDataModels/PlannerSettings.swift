//
//  PlannerSettings.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import SwiftData
import SwiftUI

@Model
class PlannerSettings {

    // Maps Calendar events IDs to system image names.
    var iconMap: [String: String] = [:]
    
    // Set of calendar IDs to exclude from planners.
    var hiddenCalendarIds: Set<String> = []
    
    var homeLocation: Location?

    init() {}
}
