//
//  bulkDeletePlannerEventConfig.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deletePlannerEventConfig(
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

// MARK: - Bulk Delete

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

// MARK: - Completed Bulk Delete

func bulkDeleteCompletedPlannerEventConfig(
    completedEvents: [PlannerEvent],
    dateLabel: String,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            "Delete completed \("event".pluralized(from: completedEvents.count)) from \(dateLabel)?",
        message: deleteMessage(for: completedEvents),
        actions: [
            ConfirmationAction(
                title:
                    "Delete \(completedEvents.count) \("Event".pluralized(from: completedEvents.count))",
                handler: delete
            )
        ]
    )
}

// MARK: - Canceled Bulk Delete

func deleteCanceledEventsConfig(
    canceledEvents: [PlannerEvent],
    dateLabel: String,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            "Delete canceled \("event".pluralized(from: canceledEvents.count)) from \(dateLabel)?",
        message: deleteMessage(for: canceledEvents),
        actions: [
            ConfirmationAction(
                title:
                    "Delete \(canceledEvents.count) \("Event".pluralized(from: canceledEvents.count))",
                handler: delete
            )
        ]
    )
}

// MARK: - Helpers

private func deleteMessage(for events: [PlannerEvent]) -> String {
    let hasCalendarEvent = events.contains(where: {
        $0.calendarEvent != nil
    })

    guard hasCalendarEvent else {
        return genericDeleteWarning
    }

    return
        "Associated calendar events will not be deleted. \(genericDeleteWarning)"
}
