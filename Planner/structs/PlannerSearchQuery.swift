//
//  PlannerSearchQuery.swift
//  Planner
//
//  Created by Alex Green on 3/16/26.
//

// Clean

import Fuse
import SwiftDate

struct PlannerSearchQuery {
    let text: String
    let filteredCalendarIds: Set<String>
    let filterPast: Bool

    // Helper Variables for filtering
    let todayStartOfDay: DateInRegion
    let fuse: Fuse
}
