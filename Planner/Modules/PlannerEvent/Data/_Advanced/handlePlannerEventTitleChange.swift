//
//  handlePlannerEventTitleChange.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    @MainActor
    func handlePlannerEventTitleChange(
        _ event: PlannerEvent,
        in planner: Planner,
        plannerDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {
        if let calendarEvent = event.calendarEvent {
            // Event is a calendar event. Update its title in the calendar.
            calendarEvent.title = event.title
            _ = eventKitStore.attemptUpdateEvent(calendarEvent)
            return
        }

        // Scan the title for a date.
        guard let defaultLocation,
              let (time, updatedText) = event.title.extractTime(for: plannerDay)
        else {
            updatePlannerEventRoutineVariance(
                event,
                in: plannerDay.region.timeZone,
                sourcePlanner: planner
            )
            return
        }

        event.title = updatedText
        event.location = defaultLocation
        event.time = time
        updatePlannerEventRoutineVariance(
            event,
            in: plannerDay.region.timeZone,
            sourcePlanner: planner
        )

        safeSave("handlePlannerEventTitleChange")
    }
}
