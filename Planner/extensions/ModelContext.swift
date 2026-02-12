//
//  ModelContext.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {

    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) {
        if planners.first != nil {
            return
        }

        let planner = Planner(datestamp: datestamp, location: nil)
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
    func ensurePlannerSettings(
        settings: [PlannerSettings]
    ) {
        if settings.first != nil {
            return
        }

        let newSettings = PlannerSettings()
        insert(newSettings)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to create initial PlannerSettings: \(error)"
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

    @MainActor
    func deleteStaleCalendarEventPositions(
        in settings: CalendarSettings,
        with eventIds: Set<String>
    ) {

        // Remove any sort index whose event ID no longer exists in the calendar.
        settings.sortIndexMap.keys
            .filter { !eventIds.contains($0) }
            .forEach { staleKey in
                print("Deleting sort index for calendar event: \(staleKey)")
                settings.sortIndexMap.removeValue(forKey: staleKey)
            }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

    @MainActor
    func deleteOldPlanners(
        from planners: [Planner],
        before cutoffDate: Date
    ) {

        let cutoffDatestamp = cutoffDate.toFormat("yyyy-MM-dd")

        for planner in planners {
            if planner.datestamp < cutoffDatestamp {
                print("Deleting planner: \(planner.datestamp)")
                delete(planner)
            }
        }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

    @MainActor
    func deleteCheckedPlans(
        from planner: Planner
    ) {

        for event in planner.events {
            if event.isChecked {
                print("Deleting checked event: \(event.id)")
                delete(event)
            }
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete checked plans: \(error)"
            )
        }
    }

    @MainActor
    func deletePlannerEvents(
        _ events: [PlannerEvent]
    ) {

        for event in events {
            delete(event)
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete plan: \(error)"
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
