//
//  ModelContext+Checklists.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    // MARK: - ENSURE

    @MainActor
    func ensureRootFolder() {
        let existingRoots =
            (try? fetch(
                FetchDescriptor<ChecklistItem>(
                    predicate: #Predicate<ChecklistItem> { item in
                        item.parent == nil
                    }
                )
            )) ?? []

        if existingRoots.first != nil {
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
        safeSave("checklistItem.ensureRootFolder")
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

        let newItem = ChecklistItem(
            type: .item,
            sortIndex: sortIndex,
            parent: parent
        )

        insert(newItem)

        return newItem.stableId

        // Note: Don't save the context here.
        // It can cause flickered duplicates in the list.
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

        safeSave("checklistItem.moveChecklistItem")
    }

    @MainActor
    func updateChecklistItem(
        sourceItem: ChecklistItem?,
        parent: ChecklistItem?,
        draftChecklistItem: ChecklistItem
    ) {

        draftChecklistItem.title = draftChecklistItem.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

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
            insert(
                ChecklistItem(
                    type: draftChecklistItem.type,
                    title: draftChecklistItem.title,
                    color: draftChecklistItem.color,
                    sortIndex: sortIndex,
                    parent: parent
                )
            )
        }

        safeSave("checklistItem.handleChecklistItemChange")
    }

    @MainActor
    func transferChecklistItems(
        _ items: [ChecklistItem],
        into destination: ChecklistItem
    ) {
        do {
            try transaction {

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

        safeSave("checklistItem.transferChecklistItems")
    }

    // MARK: - DELETE

    @MainActor
    func deleteChecklistItems(_ items: [ChecklistItem]) {
        do {
            try transaction {
                items.forEach { self.delete($0) }
            }
        } catch {
            assertionFailure(
                "ERROR checklistItem.deleteChecklistItems: \(error)"
            )
            return
        }

        safeSave("checklistItem.deleteChecklistItems")
    }
}
