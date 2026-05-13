//
//  _ChecklistItem.swift
//  Planner
//
//  Created by Alex Green on 1/24/26.
//
import SwiftData
import SwiftUI

// Clean

extension ChecklistItem {

    var safeItems: [ChecklistItem] {
        self.items ?? []
    }

    var path: String {
        var reversePath: [String] = []

        var current: ChecklistItem? = self.parent
        while let item = current {
            reversePath.append(item.title)
            current = item.parent
        }

        return reversePath.reversed().joined(separator: " / ")
    }

    // Recursively determines if the given type exists anywhere in the item's tree.
    func hasChildType(
        _ type: ChecklistItemType,
        excluding excludedIds: Set<UUID>
    ) -> Bool {

        if type == .folder, self.parent == nil,
            !excludedIds.contains(self.stableId)
        {
            // Edge case: looking for a folder, and this is the root folder.
            return true
        }

        for item in self.safeItems where !excludedIds.contains(item.stableId) {

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

    // Recursively collects folders throughout the item's tree.
    func folders(
        excluding excludedIds: Set<UUID>
    ) -> [ChecklistItem] {
        var folders: [ChecklistItem] = []

        if type == .folder, !excludedIds.contains(self.stableId) {
            // Edge case: count this item if it is a folder.
            folders.append(self)
        }

        for item in self.safeItems where !excludedIds.contains(item.stableId) {

            if item.type == .folder {
                folders.append(contentsOf: item.folders(excluding: excludedIds))
            }
        }

        return folders
    }

}
