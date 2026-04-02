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
        sourceDay: DateInRegion?,
        sourcePlannerEvent: PlannerEvent?,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) -> DateInRegion?  // The planner day the event is now in.
    {

        var destinationDay: DateInRegion?

        if let sourcePlannerEvent {

            guard let calendarEvent, !calendarEvent.isAllDay else {

                // The calendar event is deleted or all-day. Remove the storage record.
                self.delete(sourcePlannerEvent)
                return nil
            }

            // The calendar event is timed. Sync the storage record with the calendar event.
            sourcePlannerEvent.syncWithCalendarEvent(calendarEvent)
            destinationDay = self.ensureValidSortDate(
                for: sourcePlannerEvent,
                settings: settings,
                sourceDay: sourceDay
            )

        } else if let calendarEvent {

            destinationDay = self.getEarliestPlannerDay(
                for: calendarEvent.startDate,
                settings: settings
            )

            self.createPlannerEvent(
                for: calendarEvent,
                in: destinationDay
            )

        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDay
    }

}
