//
//  PlannerEventDeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deletePlannerEventConfig(
    event: PlannerEvent,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title: deleteSingleItemMessage(
            title: event.title,
            type: "event",
            inForm: inForm
        ),
        message: {
            if event.calendarContext == nil {
                return UI.GENERIC_DELETE_WARNING
            }
            
            return
                "Event will be removed from your calendar. \(UI.GENERIC_DELETE_WARNING)"
        }(),
        actions: [
            ConfirmationAction(
                title: "Delete Event",
                handler: delete
            ),
        ]
    )
}

// MARK: - Bulk Delete Selections

func bulkDeletePlannerEventConfig(
    events: [PlannerEvent],
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = events.count
    
    if count == 1 {
        return deletePlannerEventConfig(
            event: events.first!,
            delete: delete
        )
    }

    return ConfirmationConfig(
        title: "Delete \(count) events?",
        message: {
            let hasCalendarEvent = events.contains(where: {
                $0.calendarContext != nil
            })

            if hasCalendarEvent {
                return
                    "Associated calendar events will also be deleted. \(UI.GENERIC_DELETE_WARNING)"
            }

            return UI.GENERIC_DELETE_WARNING
        }(),
        actions: [
            ConfirmationAction(
                title:
                "Delete \(count) Events",
                handler: delete
            ),
        ]
    )
}

// MARK: - Bulk Delete Category: Completed

func bulkDeleteCompletedPlannerEventConfig(
    completedEventCount: Int,
    dateLabel: String,
    hasCalendarAccess: Bool,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
        "Delete completed events from \(dateLabel)?",
        message: deleteCategoryMessage(hasCalendarAccess: hasCalendarAccess),
        actions: [
            ConfirmationAction(
                title:
                "Delete ^[\(completedEventCount) Event](inflect: true)",
                handler: delete
            ),
        ]
    )
}

// MARK: - Bulk Delete Category: Canceled

func deleteCanceledEventsConfig(
    canceledEventCount: Int,
    dateLabel: String,
    hasCalendarAccess: Bool,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
        "Delete canceled events from \(dateLabel)?",
        message: deleteCategoryMessage(hasCalendarAccess: hasCalendarAccess),
        actions: [
            ConfirmationAction(
                title:
                "Delete ^[\(canceledEventCount) Event](inflect: true)",
                handler: delete
            ),
        ]
    )
}

// MARK: - Helpers

private func deleteCategoryMessage(
    hasCalendarAccess: Bool
) -> String {
    guard hasCalendarAccess else {
        return UI.GENERIC_DELETE_WARNING
    }

    return
        "Associated calendar events will not be deleted. \(UI.GENERIC_DELETE_WARNING)"
}
