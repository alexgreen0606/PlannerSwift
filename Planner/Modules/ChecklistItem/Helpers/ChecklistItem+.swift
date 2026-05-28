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

    var path: String {
        var reversePath: [String] = []

        var current: ChecklistItem? = parent
        while let item = current {
            reversePath.append(item.title)
            current = item.parent
        }

        return reversePath.reversed().joined(separator: " / ")
    }

    /// Determines whether this item or any descendant matches the given type.
    func containsType(
        _ type: ChecklistItemType,
        excluding excludedIds: Set<UUID> = [],
        /// An item that should not count as a direct match, though its descendants may still match.
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

    /// Collects all folders, including this item and all its descendants.
    func folders(
        excluding excludedIds: Set<UUID> = [],
        /// An item that should not be included, though its descendants can be.
        skipId: UUID?
    ) -> [ChecklistItem] {
        guard !excludedIds.contains(stableId) else {
            return []
        }

        var folders: [ChecklistItem] = []

        if stableId != skipId, self.type == .folder {
            folders.append(self)
        }

        for item in safeItems {
            folders.append(
                contentsOf: item.folders(excluding: excludedIds, skipId: skipId)
            )
        }

        return folders
    }
}
