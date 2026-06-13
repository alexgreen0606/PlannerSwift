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
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) {
        // Assemble the events in reverse-chronological ordering so they
        // are inserted correctly.
        let reverseSortedEvents = plannerEvents.sorted {
            $0.sortDate > $1.sortDate
        }

        for event in reverseSortedEvents {
            if let calendarContext = event.calendarContext,
                let ekEvent = ekEventStore.getEkEvent(for: event)
            {
                // MARK: Event is a calendar event. Update the calendar record.

                guard ekEvent.calendar.allowsContentModifications else {
                    continue
                }

                // Shift the start and end dates and save.
                ekEvent.startDate = ekEvent.startDate + days
                ekEvent.endDate = ekEvent.endDate + days

                calendarContext.startDate = ekEvent.startDate
                calendarContext.endDate = ekEvent.endDate

                if !ekEventStore.attemptUpdateEvent(ekEvent) {
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
