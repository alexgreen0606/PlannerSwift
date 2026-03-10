//
//  ChecklistItemExtension.swift
//  Planner
//
//  Created by Alex Green on 1/24/26.
//
import SwiftData
import SwiftUI

// Clean

extension ChecklistItem {

    var path: String {
        var reversePath: [String] = []

        var current: ChecklistItem? = self.parent
        while let item = current {
            reversePath.append(item.title)
            current = item.parent
        }

        return reversePath.reversed().joined(separator: " / ")
    }

    var deleteConfirmation: String {
        "Delete this entire \(self.type.rawValue)?"
    }

    var deleteWarning: String {
        "\(self.items.isEmpty ? "" : "All \(self.type.childrenLabel) will be lost. ")This action is irreversible."
    }

    // Recursively determines if the given type exists anywhere in the item's tree.
    func hasChildType(
        _ type: ChecklistItemType,
        excluding excludedIds: Set<UUID>
    ) -> Bool {
        for item in items {
            guard !excludedIds.contains(item.stableId) else { continue }

            if item.type == type {
                return true
            }

            if item.type == .folder,
                item.hasChildType(type, excluding: excludedIds)
            {
                return true
            }
        }

        return false
    }

    // MARK: - Data Modifiers

    @MainActor
    func inheritItems(_ itemsToMove: [ChecklistItem]) {

        var sortedExistingItems = items.sorted { $0.sortIndex < $1.sortIndex }
        let sortedItemsToMove = itemsToMove.sorted {
            $0.sortIndex < $1.sortIndex
        }

        for item in sortedItemsToMove {

            // Add item to the bottom of the new list.
            let newSortIndex = generateSortIndex(
                index: sortedExistingItems.count,
                sortedItems: sortedExistingItems
            )
            item.sortIndex = newSortIndex
            sortedExistingItems.append(item)

            items.append(item)
            item.parent = self
        }
    }

}
