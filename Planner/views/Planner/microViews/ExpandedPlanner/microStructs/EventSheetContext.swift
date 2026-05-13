//
//  EventSheetContext.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import EventKit

// Note: Moving this to separate file broke ZOOM transitions of file rows.
// If this issue returns, move back to ExpandedPlanner.
struct EventSheetContext: Identifiable {
    var plannerEvent: PlannerEvent?
    var calendarEvent: EKEvent?

    var id: String {
        if let plannerEventId = plannerEvent?.stableId {
            return "\(plannerEventId)"
        }

        if let calEvent = calendarEvent {
            return calEvent.transitionId
        }

        return "FALLBACK_NO_EVENT"
    }
}
