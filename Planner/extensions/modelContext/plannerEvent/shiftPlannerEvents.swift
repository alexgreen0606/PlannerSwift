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
        sourceDay: DateInRegion,
        targetDatestamp: String,
        settings: PlannerSettings,
        eventStore: EKEventStore
    ) {

        // Load in the planner for the selected datestamp.
        // This will only be used for untimed events.
        let destinationPlanner = getPlanner(for: targetDatestamp)
        guard
            let destinationPlannerDay = destinationPlanner.datestamp.startOfDay(
                in: destinationPlanner.region(settings: settings)
            )
        else {
            return
        }

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

            if !event.hasTime {

                // Untimed events MUST have their date set to the planner's start date.
                event.date = destinationPlannerDay.date

            } else {
                event.date = event.date + days
            }

            let _ = self.ensureValidSortDate(
                for: event,
                settings: settings,
                sourceDay: sourceDay
            )
        }

        self.safeSave("shiftPlannerEvents")
    }

}
