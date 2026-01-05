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
    func ensureCalendarSettings(
        settings: [CalendarSettings]
    ) -> CalendarSettings {
        if let existing = settings.first {
            return existing
        }

        let newSettings = CalendarSettings()
        insert(newSettings)

        do {
            try save()
        } catch {
            assertionFailure("Failed to create initial CalendarSettings: \(error)")
        }

        return newSettings
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
