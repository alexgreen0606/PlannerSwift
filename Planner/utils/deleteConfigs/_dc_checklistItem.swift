//
//  bulkDeleteChecklistItemConfig.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// Clean

// TODO: move somewhere else
let genericDeleteWarning: String = "This can't be undone."

func singleDeleteChecklistItemConfig(
    item: ChecklistItem,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title: "Delete \(item.type.rawValue) \"\(item.title)\"?",
        message: {
            if item.safeItems.isEmpty {
                return genericDeleteWarning
            }

            return
                "Contents within this \(item.type.rawValue) will also be deleted. \(genericDeleteWarning)"
        }(),
        actions: [
            ConfirmationAction(
                title: "Delete \(item.type.rawValue.capitalized)",
                handler: delete
            )
        ]
    )
}

func bulkDeleteChecklistItemConfig(
    items: [ChecklistItem],
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = items.count
    if count == 1 {
        return singleDeleteChecklistItemConfig(
            item: items.first!,
            delete: delete
        )
    }

    let childType = checklistItemsType(items)
    return ConfirmationConfig(
        title: "Delete \(count) \(childType.capitalized)s?",
        message:
            "Contents within these \(childType)s will also be deleted. \(genericDeleteWarning)",
        actions: [
            ConfirmationAction(
                title:
                    "Delete \(count) \(childType.capitalized)s",
                handler: delete
            )
        ]
    )
}
