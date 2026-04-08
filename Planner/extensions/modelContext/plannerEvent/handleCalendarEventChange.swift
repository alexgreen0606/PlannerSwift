//
//  handleCalendarEventChange.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData
import SwiftDate

// Clean

extension ModelContext {

    @MainActor
    func handleCalendarEventChange(
        _ calendarEvent: EKEvent?,
        sourceDatestamp: String?,
        sourcePlannerEvent: PlannerEvent?,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) -> String?  // The datestamp the event is now in.
    {

        var destinationDatestamp: String?

        if let sourcePlannerEvent {

            guard let calendarEvent, !calendarEvent.isAllDay else {

                // The calendar event is deleted or all-day. Remove the storage record.
                self.delete(sourcePlannerEvent)

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
            destinationDatestamp = self.ensureValidSortDate(
                for: sourcePlannerEvent,
                settings: settings,
                sourceDatestamp: sourceDatestamp
            )

        } else if let calendarEvent {

            let destinationDay = self.getEarliestPlannerDay(
                for: calendarEvent.startDate,
                settings: settings
            )

            self.createPlannerEvent(
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
