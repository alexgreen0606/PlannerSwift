//
//  ChecklistItemExtension.swift
//  Planner
//
//  Created by Alex Green on 1/24/26.
//
import SwiftData

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
    
    // TODO: Fails due to forcing self to re-evaluate its items on each iteration.
    func inheritItems(_ itemsToMove: [ChecklistItem]) {
        let items = itemsToMove

        for item in items {
            print("\(item.parent!.title) -> \(item.title) -> \(self.title)")
            item.parent = self
        }

        normalizeSortIndexesSafely()
    }
    
    private func normalizeSortIndexesSafely() {
        let sorted = items.sorted { $0.sortIndex < $1.sortIndex }

        for (index, item) in sorted.enumerated() {
            item.sortIndex = Double(index)
        }
    }

    func hasChildType(_ type: ChecklistItemType, excluding excludedIds: Set<PersistentIdentifier>) -> Bool {
        for item in items {
            if excludedIds.contains(item.id) { continue }

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
