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
    ) -> // The datestamps the event is now in.
        Set<String>
    {
        if let sourcePlannerEvent {
            if let routineEvent = sourcePlannerEvent.routineEvent,
               let sourcePlanner,
               sourcePlannerEvent.routineEventVariant == nil
            {
                // MARK: The initial event is a routine event. Mark it as a variant.

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

            guard let calendarEvent, !calendarEvent.isAllDay else {
                // MARK: The calendar event is deleted or all-day. Remove the storage record.

                delete(sourcePlannerEvent)

                if let startDate = calendarEvent?.startDate {
                    // MARK: Event is all-day. Return a set of all datestamps the event exists in.

                    return Set(
                        getSortedPlannerStartOfDays(
                            for: startDate,
                            endTime: calendarEvent?.endDate,
                            settings: settings
                        ).map(\.datestamp)
                    )
                }

                return []
            }

            // MARK: The calendar event is timed. Sync the storage record with the calendar event.

            sourcePlannerEvent.syncWithCalendarEvent(calendarEvent)

            return ensureValidSortDate(
                for: sourcePlannerEvent,
                settings: settings,
                sourceDatestamp: sourcePlanner?.datestamp
            )

        } else if let calendarEvent {
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

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return []
    }
}
