//
//  ModelContext+ChecklistItem.swift
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
        let rootFolders: [ChecklistItem]

        do {
            rootFolders = try fetch(
                FetchDescriptor(
                    predicate: ChecklistItem.rootFolders
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+ChecklistItem ensureRootFolder: \(error)"
            )
            return
        }

        switch rootFolders.count {
        case 0:
            insert(
                ChecklistItem(
                    title: "Checklists",
                    type: .folder
                )
            )

            safeSave("ModelContext+ChecklistItem ensureRootFolder")

        case 1:
            break

        default:
            deduplicateRootFolder(rootFolders: rootFolders)
        }
    }

    @MainActor
    private func deduplicateRootFolder(
        rootFolders: [ChecklistItem]
    ) {
        guard let merged = rootFolders.first else {
            return
        }

        for folder in rootFolders.dropFirst() {

            // Merge items.
            for item in folder.safeItems {
                merged.items.safeAppend(item)
                item.parent = merged
            }

            folder.items = nil

            delete(folder)
        }

        safeSave("ModelContext+ChecklistItem deduplicateRootFolder")
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
        sortedSiblingItems: [ChecklistItem]?,
        draftItem: ChecklistItem
    ) {
        draftItem.title = draftItem.title.trimmed
        draftItem.notes = draftItem.notes.trimmed
        draftItem.value = draftItem.draftValue

        if let sourceItem {
            // Edit existing item.
            sourceItem.title = draftItem.title
            sourceItem.color = draftItem.color
            sourceItem.value = draftItem.value
            sourceItem.variants = draftItem.variants
            sourceItem.notes = draftItem.notes
            sourceItem.hideToggles = draftItem.hideToggles

            // Note: Do not update the type. An item's type will never change.

        } else if let parentItem, let sortedSiblingItems {

            let sortIndex = generateSortIndex(
                index: 0,
                sortedItems: sortedSiblingItems
            )

            // Create new item.
            insert(
                ChecklistItem(
                    draft: draftItem,
                    sortIndex: sortIndex,
                    parent: parentItem
                )
            )
        }

        safeSave("ModelContext+ChecklistItem updateChecklistItem")
    }

    @MainActor
    func handleChecklistItemChange(
        item: ChecklistItem
    ) {
        if let (value, updatedText) = item.title.extractValue(),
            !updatedText.trimmed.isEmpty
        {
            // MARK: Title has a value.
            item.title = updatedText
            item.value = value
            item.syncDraft()
        }

        safeSave("ModelContext+ChecklistItem handleChecklistItemChange")
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

        safeSave("ModelContext+ChecklistItem moveChecklistItem")
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
                "ERROR ModelContext+ChecklistItem transferChecklistItems transaction: \(error)"
            )
            return
        }

        safeSave("ModelContext+ChecklistItem transferChecklistItems")
    }
}
