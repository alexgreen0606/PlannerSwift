//
//  shiftPlannerEvents.swift
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
    func shiftPlannerEvents(
        _ plannerEvents: [PlannerEvent],
        days: DateComponents,
        sourceDatestamp: String,
        destinationDatestamp: String,
        eventStore: EKEventStore,
        settings: PlannerSettings
    ) {
        // Assemble the events in reverse-chronological ordering so they
        // are inserted correctly.
        let reverseSortedEvents = plannerEvents.sorted {
            $0.sortDate > $1.sortDate
        }

        for event in reverseSortedEvents {
            if let calEvent = event.calendarEvent {
                // MARK: Event is a calendar event. Update the calendar record.

                guard calEvent.calendar.allowsContentModifications else {
                    continue
                }

                // Shift the start and end dates and save.
                calEvent.startDate = calEvent.startDate + days
                calEvent.endDate = calEvent.endDate + days

                if !eventStore.attemptUpdateEvent(calEvent) {
                    // The update failed. Skip this event.
                    continue
                }
            }

            if let time = event.time {
                event.time = time + days
            }

            event.datestamp = destinationDatestamp

            // Place the event at the top of its new planner.
            _ = ensureValidSortDate(
                for: event,
                settings: settings,
                sourceDatestamp: sourceDatestamp
            )
        }

        safeSave("shiftPlannerEvents")
    }
}
