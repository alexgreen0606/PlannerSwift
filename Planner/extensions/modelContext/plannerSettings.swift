//
//  plannerSettings.swift
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
        plannerSettings: PlannerSettings
    ) -> [PlannerEvent] {

        let calendarPlannerEvents =
            plannerSettings.buildCalendarPlannerEvents(calendarEvents: events)

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerSettings.buildCalendarPlannerEvents: \(error)"
            )
        }

        return calendarPlannerEvents
    }

    @MainActor
    func togglePlannerEvent(
        _ event: PlannerEvent,
        plannerSettings: PlannerSettings
    ) -> Bool {

        let wasContextUpdated = plannerSettings.toggleEvent(event)

        if wasContextUpdated {
            do {
                try save()
            } catch {
                assertionFailure(
                    "ERROR plannerSettings.togglePlannerEvent: \(error)"
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
