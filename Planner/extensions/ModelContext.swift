//
//  ModelContext.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import SwiftData

extension ModelContext {
    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) -> Planner {
        if let existing = planners.first {
            return existing
        }

        let planner = Planner(datestamp: datestamp)
        insert(planner)

        do {
            try save()
        } catch {
            assertionFailure("Failed to create Planner for \(datestamp): \(error)")
        }

        return planner
    }

    @MainActor
    func ensureCalendarEventPositions(
        positions: [CalendarEventPositions]
    ) -> CalendarEventPositions {
        if let existing = positions.first {
            return existing
        }

        let newPositions = CalendarEventPositions()
        insert(newPositions)

        do {
            try save()
        } catch {
            assertionFailure("Failed to create initial CalendarEventPositions: \(error)")
        }

        return newPositions
    }

    @MainActor
    func ensureRootFolder(
        rootFolders: [ChecklistItem]
    ) -> ChecklistItem {
        if let storageRoot = rootFolders.first {
            return storageRoot
        }

        let newRoot = ChecklistItem(
            type: .folder,
            title: "Checklists",
            color: .label,
            sortIndex: 0
        )
        insert(newRoot)

        do {
            try save()
        } catch {
            assertionFailure("Failed to create the Root Folder: \(error)")
        }

        return newRoot
    }
}
