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

// Clean

extension ModelContext {

    @MainActor
    func shiftPlannerEvents(
        _ events: [PlannerEvent],
        days: DateComponents,
        sourceDatestamp: String,
        targetDatestamp: String,
        settings: PlannerSettings,
        eventStore: EKEventStore
    ) {

        // Assemble the events in reverse-chronological ordering so they
        // are inserted correctly.
        let reverseSortedEvents = events.sorted { $0.sortDate > $1.sortDate }

        for event in reverseSortedEvents {

            if let calEvent = event.calendarEvent {

                guard calEvent.calendar.allowsContentModifications else {
                    continue
                }

                // Shift the start and end dates and save.
                calEvent.startDate = calEvent.startDate + days
                calEvent.endDate = calEvent.endDate + days

                if !eventStore.updateEvent(calEvent) {
                    continue
                }
            }

            if let time = event.time {
                event.time = time + days
            }

            event.datestamp = targetDatestamp

            let _ = ensureValidSortDate(
                for: event,
                settings: settings,
                sourceDatestamp: sourceDatestamp
            )
        }

        self.safeSave("shiftPlannerEvents")
    }

}
