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

    var deleteConfirmation: String {
        "Delete \(self.type.rawValue) \"\(self.title)\"?"
    }

    var deleteWarning: String {
        guard !self.safeItems.isEmpty else {
            return "This can't be undone."
        }
        return "This will delete all \(self.type.childrenLabel) in this \(self.type.rawValue). This can't be undone."
    }

    // Recursively determines if the given type exists anywhere in the item's tree.
    func hasChildType(
        _ type: ChecklistItemType,
        excluding excludedIds: Set<UUID>
    ) -> Bool {

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

}
