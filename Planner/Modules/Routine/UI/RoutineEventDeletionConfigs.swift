//
//  RoutineEventDeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deleteRoutineEventConfig(
    routineEvent: RoutineEvent,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            deleteSingleItemMessage(
                title: routineEvent.title,
                type: "recurring event",
                inForm: inForm
            ),
        message:
            "Associated planner and calendar events will be deleted. \(UI.GENERIC_DELETE_WARNING)",
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
    routineEvent: RoutineEvent,
    weekday: Weekday,
    remove: @escaping () -> Void,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    if routineEvent.safeWeekdayInstances.count < 2 {
        return deleteRoutineEventConfig(routineEvent: routineEvent, delete: delete)
    }

    return ConfirmationConfig(
        title:
            "Remove \"\(routineEvent.title)\" from \(weekday.label)s?",
        message:
            "Associated planner and calendar events will be deleted. \(UI.GENERIC_DELETE_WARNING)",
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
    routineEvents: [RoutineEvent],
    weekday: Weekday,
    remove: @escaping () -> Void,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = routineEvents.count
    
    if count < 2 {
        return removeRoutineEventFromWeekdayConfig(
            routineEvent: routineEvents.first!,
            weekday: weekday,
            remove: remove,
            delete: delete
        )
    }

    return ConfirmationConfig(
        title: "Remove \(count) events from \(weekday.label)s?",
        message:
            "Associated planner and calendar events will be deleted. \(UI.GENERIC_DELETE_WARNING)",
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
            "Associated planner and calendar events will be deleted. \(UI.GENERIC_DELETE_WARNING)",
        actions: [
            ConfirmationAction(
                title: "Delete \(weekday.label) Routine",
                handler: delete
            )
        ]
    )
}
