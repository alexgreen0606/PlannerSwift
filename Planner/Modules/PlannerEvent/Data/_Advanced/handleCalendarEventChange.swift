//
//  handleCalendarEventChange.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func handleCalendarEventChange(
        _ calendarEvent: EKEvent?,
        sourcePlannerEvent: PlannerEvent?,
        sourcePlanner: Planner?,
        plannerSyncService: PlannerSyncService,
        settings: PlannerSettings
    ) -> /// The datestamps the event is now in.
        Set<String>
    {
        let sourceWasRecurringEvent =
            sourcePlannerEvent?.calendarContext?.ekEvent?.hasRecurrenceRules
            == true
        let finalIsRecurringEvent = calendarEvent?.hasRecurrenceRules == true

        if let sourcePlannerEvent {
            // MARK: A planner event already exists. Sync it with the updated calendar event.

            if let routineEvent = sourcePlannerEvent.routineEvent,
                let sourcePlanner,
                sourcePlannerEvent.routineEventVariant == nil
            {
                // MARK: The planner event is a routine event. Mark it as a variant.

                let newRoutineEventVariant = RoutineEventVariant(
                    routineEvent: routineEvent,
                    planner: sourcePlanner,
                    plannerEvent: sourcePlannerEvent,
                    calendarItemExternalIdentifier: calendarEvent?
                        .calendarItemExternalIdentifier
                )

                routineEvent.variants?.append(newRoutineEventVariant)
                sourcePlanner.routineEventVariants?.append(
                    newRoutineEventVariant
                )
                sourcePlannerEvent.routineEventVariant = newRoutineEventVariant

                insert(newRoutineEventVariant)
            }

            guard let calendarEvent else {
                // MARK: The calendar event was deleted. Remove the storage record.

                delete(sourcePlannerEvent)
                return []
            }

            // MARK: Sync the storage record with the calendar event.

            sourcePlannerEvent.syncWithCalendarEvent(calendarEvent)

            return ensureValidSortDate(
                for: sourcePlannerEvent,
                settings: settings,
                sourceDatestamp: sourcePlanner?.datestamp
            )

        } else if let calendarEvent {
            // MARK: A planner event doesn't exist. Create one for the calendar event.

            let sortedStartsOfDays = getSortedPlannerStartOfDays(
                for: calendarEvent.startDate,
                endTime: calendarEvent.endDate,
                settings: settings
            )

            if let destinationStartOfDay = sortedStartsOfDays.first {
                createPlannerEvent(
                    for: calendarEvent,
                    on: destinationStartOfDay
                )
            }

            return Set(sortedStartsOfDays.map(\.datestamp))
        }

        // MARK: Re-sync calendar events if source or final event is recurring.
        if sourceWasRecurringEvent || finalIsRecurringEvent {
            DispatchQueue.main.async(
                execute: plannerSyncService.syncCalendar
            )
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return []
    }
}
