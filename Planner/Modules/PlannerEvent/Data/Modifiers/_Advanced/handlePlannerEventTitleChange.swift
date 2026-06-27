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
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) {
        if plannerEvent.eKEventContext != nil {
            // MARK: Event is a calendar event. Update its title in the calendar.

            guard
                let ekEvent = ekEventStore.getEkEvent(for: plannerEvent),
                ekEvent.calendar.allowsContentModifications
            else {
                return
            }

            ekEvent.title = plannerEvent.title

            _ = ekEventStore.attemptUpdateEvent(ekEvent)

            return
        }

        if let plannerLocation,
            let (time, updatedText) = plannerEvent.title.extractTime(
                for: startOfDay
            )
        {
            // MARK: Title has a time value. Re-configure the event.

            plannerEvent.title = updatedText
            plannerEvent.location = plannerLocation
            plannerEvent.time = time
        }

        // MARK: Update the event's routine variance.
        plannerEvent.updateRoutineVariance(
            in: startOfDay.region.timeZone,
            settings: settings
        )

        safeSave("handlePlannerEventTitleChange")
    }
}
