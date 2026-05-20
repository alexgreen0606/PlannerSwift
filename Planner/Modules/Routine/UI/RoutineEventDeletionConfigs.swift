//
//  RoutineEventDeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deleteRoutineEventConfig(
    event: RoutineEvent,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            "Delete\(inForm ? " this" : "") recurring event\(inForm ? "" : " \"\(event.title)\"")?",
        message:
            "Associated planner and calendar events will be deleted. \(genericDeleteWarning)",
        actions: [
            ConfirmationAction(
                title: "Delete Recurring Event",
                handler: delete
            )
        ]
    )
}

// MARK: - Single Weekday Remove

func removeRoutineEventFromWeekdayConfig(
    event: RoutineEvent,
    weekday: Weekday,
    remove: @escaping () -> Void,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    if event.safeWeekdayInstances.count == 1 {
        return deleteRoutineEventConfig(event: event, delete: delete)
    }

    return ConfirmationConfig(
        title:
            "Remove \"\(event.title)\" from \(weekday.label)s?",
        message:
            "Associated planner and calendar events will be deleted. \(genericDeleteWarning)",
        actions: [
            ConfirmationAction(
                title: "Remove From \(weekday.label)s",
                role: .confirm,
                handler: remove
            ),
            ConfirmationAction(
                title: "Delete Everywhere",
                handler: delete
            ),
        ]
    )
}

// MARK: - Bulk Weekday Remove

func bulkRemoveRoutineEventFromWeekdayConfig(
    events: [RoutineEvent],
    weekday: Weekday,
    remove: @escaping () -> Void,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = events.count
    if count == 1 {
        return removeRoutineEventFromWeekdayConfig(
            event: events.first!,
            weekday: weekday,
            remove: remove,
            delete: delete
        )
    }

    return ConfirmationConfig(
        title: "Remove \(count) events from \(weekday.label)s?",
        message:
            "Associated planner and calendar events will be deleted. \(genericDeleteWarning)",
        actions: [
            ConfirmationAction(
                title:
                    "Remove \(count) Recurring Events From \(weekday.label)s",
                role: .confirm,
                handler: remove
            ),
            ConfirmationAction(
                title: "Delete \(count) Recurring Events Everywhere",
                handler: delete
            ),
        ]
    )
}

// MARK: - Routine Delete

func deleteRoutineConfig(
    weekday: Weekday,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            "Delete \(weekday.label) routine?",
        message:
            "Associated planner and calendar events will be deleted. \(genericDeleteWarning)",
        actions: [
            ConfirmationAction(
                title: "Delete \(weekday.label) Routine",
                handler: delete
            )
        ]
    )
}
