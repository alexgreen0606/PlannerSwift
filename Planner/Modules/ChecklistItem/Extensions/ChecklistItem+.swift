//
//  ChecklistItem+.swift
//  Planner
//
//  Created by Alex Green on 1/24/26.
//

import SwiftUI

extension ChecklistItem {
    var safeItems: [ChecklistItem] {
        items ?? []
    }

    var path: NavigationPath {
        var reversePath: [ChecklistItem] = []

        // Build the reverse path to the root.
        var pointer: ChecklistItem? = parent
        while let pointerItem = pointer {
            reversePath.append(pointerItem)

            pointer = pointerItem.parent
        }

        // Build the navigation path to self.
        var path = NavigationPath()
        for folder in reversePath.reversed() {
            path.append(folder)
        }

        return path
    }

    /// Determines whether this item or any descendant matches the given type.
    func containsType(
        _ type: ChecklistItemType,
        excluding excludedIds: Set<UUID> = [],
        // An item that should not count as a direct match, though its descendants may still match.
        skipId: UUID? = nil
    ) -> Bool {
        guard !excludedIds.contains(stableId) else {
            return false
        }

        if stableId != skipId, self.type == type {
            return true
        }

        for item in safeItems {
            if item.containsType(
                type,
                excluding: excludedIds,
                skipId: skipId
            ) {
                return true
            }
        }

        return false
    }

    /// Collects all items of a specific type, including this item and all its descendants.
    func items(
        matching type: ChecklistItemType,
        excluding excludedIds: Set<UUID> = [],
        // An item that should not be included, though its descendants can be.
        skipId: UUID?
    ) -> [ChecklistItem] {
        guard !excludedIds.contains(stableId) else {
            return []
        }

        var matches: [ChecklistItem] = []

        if stableId != skipId, self.type == type {
            matches.append(self)
        }

        for item in safeItems {
            matches.append(
                contentsOf: item.items(
                    matching: type,
                    excluding: excludedIds,
                    skipId: skipId
                )
            )
        }

        return matches
    }
}
