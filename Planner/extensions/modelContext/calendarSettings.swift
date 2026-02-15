//
//  calendarSettings.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {

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
    func togglePlannerEvent(
        _ event: PlannerEvent,
        calendarSettings: CalendarSettings
    ) -> Bool {

        let wasContextUpdated = calendarSettings.toggleEvent(event)
        
        if wasContextUpdated {
            do {
                try save()
            } catch {
                assertionFailure(
                    "ERROR calendarSettings.togglePlannerEvent: \(error)"
                )
            }
        }

        return wasContextUpdated
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

}
