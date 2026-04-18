//
//  bulkDeletePlannerEventConfig.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// Clean

func singleDeletePlannerEventConfig(
    event: PlannerEvent,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title: "Delete event \"\(event.title)\"?",
        message: {
            if event.calendarEvent == nil {
                return genericDeleteWarning
            }
            return
                "Event will be removed from your calendar. \(genericDeleteWarning)"
        }(),
        actions: [
            ConfirmationAction(
                title: "Delete Event",
                handler: delete
            )
        ]
    )
}

func bulkDeletePlannerEventConfig(
    events: [PlannerEvent],
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = events.count
    if count == 1 {
        return singleDeletePlannerEventConfig(
            event: events.first!,
            delete: delete
        )
    }

    return ConfirmationConfig(
        title: "Delete \(count) events?",
        message: {
            let hasCalendarEvent = events.contains(where: {
                $0.calendarEvent != nil
            })
            
            if hasCalendarEvent {
                return
                    "Associated calendar events will also be deleted. \(genericDeleteWarning)"
            }

            return genericDeleteWarning
        }(),
        actions: [
            ConfirmationAction(
                title:
                    "Delete \(count) Events",
                handler: delete
            )
        ]
    )
}
