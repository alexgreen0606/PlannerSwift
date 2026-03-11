//
//  checklistItem.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    @MainActor
    func ensureRootFolder(
        folders: [ChecklistItem]
    ) {
        if folders.first != nil {
            return
        }

        insert(
            ChecklistItem(
                type: .folder,
                title: "Checklists",
                color: .label,
                sortIndex: 0
            )
        )

        self.safeSave("checklistItem.ensureRootFolder")
    }

    @MainActor
    func createChecklistItem(
        in sortedItems: [ChecklistItem],
        near baseId: UUID?,
        offset: Int,
        parent: ChecklistItem
    ) -> UUID? {
        guard
            let targetIndex = generateTargetIndex(
                in: sortedItems,
                near: baseId,
                offset: offset
            )
        else {
            return nil
        }

        let sortIndex = generateSortIndex(
            index: targetIndex,
            sortedItems: sortedItems
        )

        let newItem = ChecklistItem(sortIndex: sortIndex, parent: parent)
        insert(newItem)

        self.safeSave("checklistItem.createChecklistItem")

        return newItem.stableId
    }

    @MainActor
    func moveChecklistItem(in sortedItems: [ChecklistItem], from: Int, to: Int)
    {
        guard from != to else { return }

        let movedItem = sortedItems[from]
        movedItem.sortIndex = generateSortIndex(
            index: to,
            sortedItems: sortedItems
        )

        self.safeSave("checklistItem.moveChecklistItem")
    }

    @MainActor
    func deleteChecklistItem(_ item: ChecklistItem) {
        self.delete(item)
        self.safeSave("checklistItem.deleteChecklistItem")
    }

    @MainActor
    func deleteChecklistItems(_ items: [ChecklistItem]) {
        items.forEach { self.delete($0) }
        self.safeSave("checklistItem.deleteChecklistItems")
    }

    @MainActor
    func handleChecklistItemChange(
        sourceItem: ChecklistItem?,
        parent: ChecklistItem?,
        draftChecklistItem: ChecklistItem
    ) -> UUID? {
        var newItemId: UUID? = nil
        
        if let sourceItem {
            // Edit the existing item.
            sourceItem.title = draftChecklistItem.title
            sourceItem.color = draftChecklistItem.color
            sourceItem.type = draftChecklistItem.type

        } else {
            // Create the new item.
            let sorted = parent?.items.sorted {
                $0.sortIndex < $1.sortIndex
            }
            let sortIndex = (sorted?.last?.sortIndex ?? 0) + 8
            let newItem = ChecklistItem(
                type: draftChecklistItem.type,
                title: draftChecklistItem.title,
                color: draftChecklistItem.color,
                sortIndex: sortIndex,
                parent: parent
            )

            newItemId = newItem.stableId
            self.insert(newItem)
        }

        self.safeSave("checklistItem.handleChecklistItemChange")
        return newItemId
    }

    @MainActor
    func transferChecklistItems(
        into destination: ChecklistItem,
        items: [ChecklistItem]
    ) {
        do {
            try transaction {
                destination.inheritItems(items)
            }
        } catch {
            assertionFailure(
                "ERROR checklistItem.transferChecklistItems: \(error)"
            )
            return
        }

        self.safeSave("checklistItem.transferChecklistItems")
    }

}
