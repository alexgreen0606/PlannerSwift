//
//  handlePlannerEventTitleChange.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func handlePlannerEventTitleChange(
        _ plannerEvent: PlannerEvent,
        in planner: Planner,
        startOfDay: DateInRegion,
        plannerLocation: Location?,
        eventKitStore: EKEventStore,
        settings: PlannerSettings
    ) {
        if let calendarEvent = plannerEvent.calendarEvent {
            // MARK: Event is a calendar event. Update its title in the calendar.

            calendarEvent.title = plannerEvent.title
            _ = eventKitStore.attemptUpdateEvent(calendarEvent)
            return
        }

        if let plannerLocation,
           let (time, updatedText) = plannerEvent.title.extractTime(for: startOfDay)
        {
            // MARK: Title has a time value. Re-configure the event.

            plannerEvent.title = updatedText
            plannerEvent.location = plannerLocation
            plannerEvent.time = time
        }

        // MARK: Update the event's routine state if needed.

        updatePlannerEventRoutineVariance(
            plannerEvent,
            in: startOfDay.region.timeZone,
            sourcePlanner: planner,
            settings: settings
        )

        safeSave("handlePlannerEventTitleChange")
    }
}
