//
//  plannerSettings.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftData
import SwiftDate
import SwiftUI
import EventKit

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
