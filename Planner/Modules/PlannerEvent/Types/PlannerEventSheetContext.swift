//
//  PlannerEventSheetContext.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import EventKit

/// Note:  In the past, moving this to separate file broke zoom transitions on planner event rows.
/// If this issue returns, move this struct back to PlannerRoot.
struct PlannerEventSheetContext: Identifiable {
    var plannerEvent: PlannerEvent

    var id: String {
        plannerEvent.transitionId
    }
}
