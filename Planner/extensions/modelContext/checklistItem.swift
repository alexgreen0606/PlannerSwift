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

        do {
            try save()
        } catch {
            assertionFailure("Failed to create the Root Folder: \(error)")
        }
    }

    @MainActor
    func createChecklistItem(
        in items: [ChecklistItem],
        near baseId: UUID?,
        offset: Int,
        parent: ChecklistItem
    ) -> UUID? {
        var targetIndex: Int? = 0

        if let baseId {
            targetIndex = generateTargetIndex(
                in: items,
                near: baseId,
                offset: offset
            )
        }

        guard let targetIndex else {
            return nil
        }

        let sortIndex = generateSortIndex(
            index: targetIndex,
            items: items
        )

        let newItem = ChecklistItem(sortIndex: sortIndex, parent: parent)

        insert(newItem)

        Task { @MainActor in
            do {
                try self.save()
            } catch {
                print("ERROR checklistItem.createChecklistItem: \(error)")
            }
        }

        return newItem.stableId
    }

    @MainActor
    func moveChecklistItem(in items: [ChecklistItem], from: Int, to: Int) {
        guard from != to else { return }

        let movedEvent = items[from]
        let remainingItems = items.filter {
            $0.stableId != movedEvent.stableId
        }

        movedEvent.sortIndex = generateSortIndex(
            index: to,
            items: remainingItems
        )

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR checklistItem.moveChecklistItem: \(error)"
            )
        }
    }

    @MainActor
    func deleteChecklistItem(_ item: ChecklistItem) {

        delete(item)

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR checklistItem.deleteChecklistItem: \(error)"
            )
        }
    }

    @MainActor
    func deleteChecklistItems(_ items: [ChecklistItem]) {
        items.forEach { delete($0) }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete checklist items: \(error)"
            )
        }
    }
}
