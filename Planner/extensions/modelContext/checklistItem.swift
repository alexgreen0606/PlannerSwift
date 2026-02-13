//
//  checklistItem.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {

    @MainActor
    func ensureRootFolder(
        folders: [ChecklistItem]
    ) {
        if folders.first != nil {
            return
        }

        insert(ChecklistItem(
            type: .folder,
            title: "Checklists",
            color: .label,
            sortIndex: 0
        ))

        do {
            try save()
        } catch {
            assertionFailure("Failed to create the Root Folder: \(error)")
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
