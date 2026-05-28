//
//  ChecklistItemDeletionConfigs.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

func deleteChecklistItemConfig(
    item: ChecklistItem,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title: deleteSingleItemMessage(
            title: item.title,
            type: item.type.rawValue,
            inForm: inForm
        ),
        message: {
            if item.safeItems.isEmpty {
                return UI.GENERIC_DELETE_WARNING
            }

            return
                "Contents within this \(item.type.rawValue) will also be deleted. \(UI.GENERIC_DELETE_WARNING)"
        }(),
        actions: [
            ConfirmationAction(
                title: "Delete \(item.type.rawValue.capitalized)",
                handler: delete
            )
        ]
    )
}

// MARK: - Bulk Delete Selections

func bulkDeleteChecklistItemsConfig(
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

    let itemsTypeLabel = checklistItemsTypeLabel(items)
    return ConfirmationConfig(
        title: "Delete \(count) \(itemsTypeLabel.capitalized)s?",
        message: {
            guard items.contains(where: { !$0.safeItems.isEmpty }) else {
                return UI.GENERIC_DELETE_WARNING
            }

            return
                "Contents within these \(itemsTypeLabel)s will also be deleted. \(UI.GENERIC_DELETE_WARNING)"
        }(),
        actions: [
            ConfirmationAction(
                title:
                    "Delete \(count) \(itemsTypeLabel.capitalized)s",
                handler: delete
            )
        ]
    )
}

// MARK: - Bulk Delete Category: Completed

func bulkDeleteCompletedChecklistItemsConfig(
    completedItems: [ChecklistItem],
    parent: ChecklistItem,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
            "Delete completed items from \"\(parent.title)\"?",
        message: UI.GENERIC_DELETE_WARNING,
        actions: [
            ConfirmationAction(
                title:
                    "Delete ^[\(completedItems.count) Item](inflect: true)",
                handler: delete
            )
        ]
    )
}
