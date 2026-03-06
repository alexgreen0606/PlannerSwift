//
//  ChecklistItemExtension.swift
//  Planner
//
//  Created by Alex Green on 1/24/26.
//
import SwiftData
import SwiftUI

extension ChecklistItem {

    var path: String {
        var components: [String] = []
        var current: ChecklistItem? = self.parent

        while let item = current {
            if !item.title.isEmpty {
                components.append(item.title)
            }
            current = item.parent
        }

        return components.reversed().joined(separator: " / ")
    }

    var deleteConfirmation: String {
        "Delete this entire \(self.type.rawValue)?"
    }

    var deleteWarning: String {
        "\(self.items.isEmpty ? "" : "All \(type.childrenLabel) will be lost. ")This action is irreversible."
    }

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

    func hasChildType(
        _ type: ChecklistItemType,
        excluding excludedIds: Set<UUID>
    ) -> Bool {
        for item in items {
            if excludedIds.contains(item.stableId) { continue }

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

    func isAncestor(of item: ChecklistItem) -> Bool {
        var node = item.parent

        while let current = node {
            if current == self {
                return true
            }
            node = current.parent
        }

        return false
    }
}
