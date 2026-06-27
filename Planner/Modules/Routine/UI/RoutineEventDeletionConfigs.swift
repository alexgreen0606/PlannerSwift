//
//  RoutineEventDeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deleteRoutineEventConfig(
    routineEventContext: RoutineEventContext,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            deleteSingleItemMessage(
                title: routineEventContext.title,
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
    routineEventContext: RoutineEventContext,
    weekday: Weekday,
    remove: @escaping () -> Void,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    if routineEventContext.safeRoutineEvents.count == 1 {
        return deleteRoutineEventConfig(
            routineEventContext: routineEventContext,
            delete: delete
        )
    }

    return ConfirmationConfig(
        title:
            "Remove \"\(routineEventContext.title)\" from \(weekday.label)s?",
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
    routineEventContexts: [RoutineEventContext],
    weekday: Weekday,
    remove: @escaping () -> Void,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = routineEventContexts.count

    if count == 1, let routineEventContext = routineEventContexts.first {
        return removeRoutineEventFromWeekdayConfig(
            routineEventContext: routineEventContext,
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
