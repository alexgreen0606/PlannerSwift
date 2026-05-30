//
//  ModelContext+Checklists.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftData
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
                title: "Checklists",
                type: .folder,
                color: .cyan,
                sortIndex: 0
            )
        )

        safeSave("ModelContext+Checklists.ensureRootFolder")
    }

    // MARK: - CREATE

    @MainActor
    func createChecklistItem(
        at index: Int,
        in sortedItems: [ChecklistItem],
        parent: ChecklistItem
    ) -> UUID {
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
    func saveChecklistItem(
        sourceItem: ChecklistItem?,
        parentItem: ChecklistItem?,
        draftItem: ChecklistItem
    ) {
        draftItem.title = draftItem.title.trimmed

        if let sourceItem {
            // Edit existing item.
            sourceItem.title = draftItem.title
            sourceItem.color = draftItem.color

            // Note: Do not update the type. An item's type will never change.

        } else {
            // TODO: pass in this as a param (probably as a context value with the parent)
            let sortedSiblings =
                parentItem?.safeItems.sorted {
                    $0.sortIndex < $1.sortIndex
                } ?? []

            let sortIndex = generateSortIndex(
                index: sortedSiblings.count,
                sortedItems: sortedSiblings
            )

            // Create new item.
            insert(
                ChecklistItem(
                    title: draftItem.title,
                    type: draftItem.type,
                    color: draftItem.color,
                    sortIndex: sortIndex,
                    parent: parentItem
                )
            )
        }

        safeSave("ModelContext+Checklists.updateChecklistItem")
    }

    @MainActor
    func moveChecklistItem(
        /// The initial index within sortedPendingItems.
        initialIndex: Int,
        /// The target index within sortedItems.
        targetIndex: Int,
        /// Only provide this when item was moved within a list that is a subset of a larger list.
        /// Example: Folders do not need to pass this. Folder items are never pending.
        sortedPendingItems: [ChecklistItem]? = nil,
        sortedItems: [ChecklistItem]
    ) {
        let sourceItems = sortedPendingItems ?? sortedItems

        let movedItem = sourceItems[initialIndex]
        movedItem.sortIndex = generateSortIndex(
            index: targetIndex,
            sortedItems: sortedItems
        )

        safeSave("ModelContext+Checklists.moveChecklistItem")
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

                    // Note: Assign both references of the relationship.
                    // Otherwise the item may be lost.
                    destination.items?.append(item)
                    item.parent = destination
                }
            }
        } catch {
            assertionFailure(
                "ERROR ModelContext+Checklists.transferChecklistItems.transaction: \(error)"
            )
            return
        }

        safeSave("ModelContext+Checklists.transferChecklistItems")
    }
}
