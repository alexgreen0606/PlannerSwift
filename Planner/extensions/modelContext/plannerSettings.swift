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
    func synchronize(
        calendarEvents events: [EKEvent],
        into plannerEvents: [PlannerEvent],
        planner: Planner,
        calendarSettings: CalendarSettings,
        plannerSettings: PlannerSettings
    ) -> [PlannerEvent] {

        let calendarPlannerEvents =
            planner.synchronizeCalendarEventPositions(
                events,
                plannerEvents: plannerEvents,
                calendarSettings: calendarSettings,
                plannerSettings: plannerSettings
            )

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerSettings.synchronize: \(error)"
            )
        }

        return calendarPlannerEvents
    }

}
