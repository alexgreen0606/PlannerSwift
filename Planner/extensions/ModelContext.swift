//
//  ModelContext.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) {
        if planners.first != nil {
            return
        }

        let planner = Planner(datestamp: datestamp)
        insert(planner)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to create Planner for \(datestamp): \(error)"
            )
        }

    }

    @MainActor
    func ensureCalendarSettings(
        settings: [CalendarSettings]
    ) {
        if settings.first != nil {
            return
        }

        let newSettings = CalendarSettings()
        insert(newSettings)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to create initial CalendarSettings: \(error)"
            )
        }

    }

    @MainActor
    func ensureRootFolder(
        rootFolders: [ChecklistItem]
    ) {
        if rootFolders.first != nil {
            return
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

    }

    // TODO: this should NOT run if the user has the delete planners after... set to never.
    @MainActor
    func deleteStaleCalendarEventPositions(
        in settings: CalendarSettings,
        with eventIds: Set<String>
    ) {

        // Remove any sort index whose event ID no longer exists in the calendar.
        settings.sortIndexMap.keys
            .filter { !eventIds.contains($0) }
            .forEach { staleKey in
                print("deleting \(staleKey)")
                settings.sortIndexMap.removeValue(forKey: staleKey)
            }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to clean calendar event sort indices: \(error)"
            )
        }
    }

    @MainActor
    func synchronize(
        calendarEvents events: [EKEvent],
        into planner: Planner?,
        with settings: CalendarSettings?
    ) -> [PlannerEvent]? {
        guard let planner = planner, let settings = settings
        else { return nil }

        let calendarPlannerEvents =
            planner.synchronizeCalendarEventPositions(
                for: events,
                from: settings
            )

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to synchronize calendar events into planner: \(error)"
            )
        }

        return calendarPlannerEvents
    }
}
