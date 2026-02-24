//
//  settings.swift
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
    func buildCalendarPlannerEvents(
        calendarEvents events: [EKEvent],
        settings: PlannerSettings
    ) -> [PlannerEvent] {

        let calendarPlannerEvents =
            settings.buildCalendarPlannerEvents(calendarEvents: events)

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR settings.buildCalendarPlannerEvents: \(error)"
            )
        }

        return calendarPlannerEvents
    }

    @MainActor
    func togglePlannerEvent(
        _ event: PlannerEvent,
        settings: PlannerSettings
    ) -> Bool {

        let wasContextUpdated = settings.toggleEvent(event)

        if wasContextUpdated {
            do {
                try save()
            } catch {
                assertionFailure(
                    "ERROR settings.togglePlannerEvent: \(error)"
                )
            }
        }

        return wasContextUpdated
    }

    @MainActor
    func deleteStaleCalendarEventPositions(
        in settings: PlannerSettings,
        with eventIds: Set<String>
    ) {

        // Remove any sort index whose event ID no longer exists in the calendar.
        settings.calendarSortDateMap.keys
            .filter { !eventIds.contains($0) }
            .forEach { staleKey in
                print("Deleting sort index for calendar event: \(staleKey)")
                settings.calendarSortDateMap.removeValue(forKey: staleKey)
            }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

}
