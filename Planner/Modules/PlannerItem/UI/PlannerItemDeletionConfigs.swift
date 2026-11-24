//
//  PlannerItemDeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 11/23/26.
//

import SwiftUI

// MARK: - Single Delete

func deletePlannerItemConfig(
    item: PlannerItem,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    return ConfirmationConfig(
        title: deleteSingleItemMessage(
            title: item.title,
            type: "event",
            inForm: inForm
        ),
        message: item.isCalendarEvent
            ? "Event will be removed from your calendar. \(UI.GENERIC_DELETE_WARNING)"
            : UI.GENERIC_DELETE_WARNING,
        actions: [
            ConfirmationAction(
                title: "Delete Event",
                handler: delete
            )
        ]
    )
}

// MARK: - Bulk Delete Selections

func bulkDeletePlannerItemConfig(
    items: [PlannerItem],
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = items.count

    if count == 1, let item = items.first {
        return deletePlannerItemConfig(
            item: item,
            delete: delete
        )
    }

    return ConfirmationConfig(
        title: "Delete \(count) events?",
        message: items.contains(where: { $0.isCalendarEvent })
            ? "Associated calendar events will also be deleted. \(UI.GENERIC_DELETE_WARNING)"
            : UI.GENERIC_DELETE_WARNING,
        actions: [
            ConfirmationAction(
                title: "Delete \(count) Events",
                handler: delete
            )
        ]
    )
}

// MARK: - Bulk Delete Category: Completed

func bulkDeleteCompletedPlannerItemConfig(
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
            )
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
