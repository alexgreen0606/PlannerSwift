//
//  handleCalendarEventChange.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func handleCalendarEventChange(
        _ calendarEvent: EKEvent?,
        sourcePlanner: Planner?,
        sourcePlannerEvent: PlannerEvent?,
        settings: PlannerSettings
    ) -> // The datestamp the event is now in.
        String?
    {
        var destinationDatestamp: String?

        if let sourcePlannerEvent {
            if let routineEvent = sourcePlannerEvent.routineEvent,
               let sourcePlanner,
               sourcePlannerEvent.routineEventVariant == nil
            {
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

                // The initial event is a routine event. Mark it as a variant.
                insert(newRoutineEventVariant)
            }

            guard let calendarEvent, !calendarEvent.isAllDay else {
                // The calendar event is deleted or all-day. Remove the storage record.
                delete(sourcePlannerEvent)

                if let startDate = calendarEvent?.startDate {
                    // Return the new destination of all-day events.
                    return getEarliestPlannerDay(
                        for: startDate,
                        settings: settings
                    )?.datestamp
                }

                return nil
            }

            // The calendar event is timed. Sync the storage record with the calendar event.
            sourcePlannerEvent.syncWithCalendarEvent(calendarEvent)
            destinationDatestamp = ensureValidSortDate(
                for: sourcePlannerEvent,
                settings: settings,
                sourceDatestamp: sourcePlanner?.datestamp
            )

        } else if let calendarEvent {
            let destinationDay = getEarliestPlannerDay(
                for: calendarEvent.startDate,
                settings: settings
            )

            createPlannerEvent(
                for: calendarEvent,
                in: destinationDay
            )

            destinationDatestamp = destinationDay?.datestamp
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDatestamp
    }
}
