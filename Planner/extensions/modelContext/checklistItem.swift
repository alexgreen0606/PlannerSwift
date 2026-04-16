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

    // MARK: - ENSURE

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

    // MARK: - CREATE

    @MainActor
    func createChecklistItem(
        at index: Int,
        in sortedItems: [ChecklistItem],
        parent: ChecklistItem
    ) -> UUID? {

        let sortIndex = generateSortIndex(
            index: index,
            sortedItems: sortedItems
        )

        let newItem = ChecklistItem(sortIndex: sortIndex, parent: parent)

        insert(newItem)
        self.safeSave("checklistItem.createChecklistItem")

        return newItem.stableId
    }

    // MARK: - UPDATE

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
    func handleChecklistItemChange(
        sourceItem: ChecklistItem?,
        parent: ChecklistItem?,
        draftChecklistItem: ChecklistItem
    ) -> UUID? {
        var newItemId: UUID? = nil
        
        draftChecklistItem.title = draftChecklistItem.title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let sourceItem {

            // Edit the existing item.
            sourceItem.title = draftChecklistItem.title
            sourceItem.color = draftChecklistItem.color
            sourceItem.type = draftChecklistItem.type

        } else {

            let sorted = parent?.safeItems.sorted {
                $0.sortIndex < $1.sortIndex
            }
            let sortIndex = (sorted?.last?.sortIndex ?? 0) + 8

            // Create a new item.
            let newItem = ChecklistItem(
                type: draftChecklistItem.type,
                title: draftChecklistItem.title,
                color: draftChecklistItem.color,
                sortIndex: sortIndex,
                parent: parent
            )
            self.insert(newItem)

            newItemId = newItem.stableId
        }

        self.safeSave("checklistItem.handleChecklistItemChange")

        return newItemId
    }

    @MainActor
    func transferChecklistItems(
        _ items: [ChecklistItem],
        into destination: ChecklistItem
    ) {
        do {
            try self.transaction {

                var sortedDestinationItems = destination.safeItems.sorted {
                    $0.sortIndex < $1.sortIndex
                }

                // Reverse-sort so they are inserted correctly.
                let sortedItemsToMove = items.sorted {
                    $0.sortIndex > $1.sortIndex
                }

                for item in sortedItemsToMove {

                    // Add item to the top of the new list.
                    item.sortIndex = generateSortIndex(
                        index: 0,
                        sortedItems: sortedDestinationItems
                    )

                    sortedDestinationItems.insert(item, at: 0)

                    // Assign both references of the relationship.
                    // Both MUST be applied or else the item may be lost.
                    destination.items?.append(item)
                    item.parent = destination
                }

            }
        } catch {
            assertionFailure(
                "ERROR checklistItem.transferChecklistItems: \(error)"
            )
            return
        }

        self.safeSave("checklistItem.transferChecklistItems")
    }

    // MARK: - DELETE

    @MainActor
    func deleteChecklistItems(_ items: [ChecklistItem]) {
        do {
            try self.transaction {
                items.forEach { self.delete($0) }
            }
        } catch {
            assertionFailure(
                "ERROR checklistItem.deleteChecklistItems: \(error)"
            )
            return
        }

        self.safeSave("checklistItem.deleteChecklistItems")
    }

}
