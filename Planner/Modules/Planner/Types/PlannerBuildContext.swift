//
//  PlannerSyncContext.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import SwiftDate

/// All data needed to build and sync a planner.
struct PlannerSyncContext {
    let planner: Planner
    let startOfDay: DateInRegion
}
