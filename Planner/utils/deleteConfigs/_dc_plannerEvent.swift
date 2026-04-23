//
//  _dc_plannerEvent.swift
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
        title:
            "Delete\(inForm ? " this" : "") event\(inForm ? "" : " \"\(event.title)\"")?",
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

// MARK: - Bulk Delete Category: Completed

func bulkDeleteCompletedPlannerEventConfig(
    completedEvents: [PlannerEvent],
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
                    "Delete \("Event".pluralized(from: completedEvents.count))",
                handler: delete
            )
        ]
    )
}

// MARK: - Bulk Delete Category: Canceled

func deleteCanceledEventsConfig(
    canceledEvents: [PlannerEvent],
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
                    "Delete \("Event".pluralized(from: canceledEvents.count))",
                handler: delete
            )
        ]
    )
}

// MARK: - Helpers

private func deleteCategoryMessage(
    hasCalendarAccess: Bool
) -> String {
    guard hasCalendarAccess else {
        return genericDeleteWarning
    }

    return
        "Associated calendar events will not be deleted. \(genericDeleteWarning)"
}
