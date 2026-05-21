//
//  ChecklistDeletionConfig.swift
//  Planner
//
//  Created by Alex Green on 4/17/26.
//

import SwiftUI

// MARK: - Single Delete

@MainActor
func deleteChecklistItemConfig(
    item: ChecklistItem,
    inForm: Bool = false,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
        "Delete\(inForm ? " this" : "") \(item.type.rawValue)\(inForm ? "" : " \"\(item.title)\"")?",
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
            ),
        ]
    )
}

// MARK: - Bulk Delete Selections

@MainActor
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
        message: {
            guard items.contains(where: { !$0.safeItems.isEmpty }) else {
                return genericDeleteWarning
            }

            return
                "Contents within these \(childType)s will also be deleted. \(genericDeleteWarning)"
        }(),
        actions: [
            ConfirmationAction(
                title:
                "Delete \(count) \(childType.capitalized)s",
                handler: delete
            ),
        ]
    )
}

// MARK: - Bulk Delete Category: Completed

@MainActor
func bulkDeleteCompletedChecklistItemConfig(
    completedItems: [ChecklistItem],
    item: ChecklistItem,
    delete: @escaping () -> Void
) -> ConfirmationConfig {
    ConfirmationConfig(
        title:
        "Delete completed items from \"\(item.title)\"?",
        message: genericDeleteWarning,
        actions: [
            ConfirmationAction(
                title:
                "Delete \("Item".inflected(for: completedItems.count))",
                handler: delete
            ),
        ]
    )
}
