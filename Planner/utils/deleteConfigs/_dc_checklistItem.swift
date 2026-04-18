//
//  _dc_checklistItem.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deleteChecklistItemConfig(
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

// MARK: - Bulk Delete

func bulkDeleteChecklistItemConfig(
    items: [ChecklistItem],
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    let count = items.count
    if count == 1 {
        return deleteChecklistItemConfig(
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

// MARK: - Completed Bulk Delete

func bulkDeleteCompletedChecklistItemConfig(
    completedItems: [ChecklistItem],
    checklist: ChecklistItem,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            "Delete completed \("item".pluralized(from: completedItems.count)) from \"\(checklist.title)\"?",
        message:
            "\(completedItems.count) \("item".pluralized(from: completedItems.count)) will be deleted from this checklist. \(genericDeleteWarning)",
        actions: [
            ConfirmationAction(
                title:
                    "Delete \(completedItems.count) \("Item".pluralized(from: completedItems.count))",
                handler: delete
            )
        ]
    )
}
