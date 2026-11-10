//
//  shiftPlannerEvent.swift
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
        todaystamp: String,
        ekEventStore: EKEventStore,
        settings: Settings
    ) -> Int {
        // Assemble the events in reverse-chronological ordering so they
        // are inserted correctly.
        let reverseSortedEvents = plannerEvents.sorted {
            $0.sortDate > $1.sortDate
        }

        let todayPlanner = getPlanner(for: todaystamp)

        var successCount = 0

        for event in reverseSortedEvents {
            let didShift = shiftPlannerEvent(
                event,
                days: days,
                sourceDatestamp: sourceDatestamp,
                destinationDatestamp: destinationDatestamp,
                todayStartOfDay: todayPlanner.startOfDay(settings: settings),
                ekEventStore: ekEventStore,
                settings: settings,
                skipSave: true
            )

            if didShift {
                successCount += 1
            }
        }

        safeSave("shiftPlannerEvent shiftPlannerEvents")

        return successCount
    }

    @MainActor
    func shiftPlannerEvent(
        _ event: PlannerEvent,
        days: DateComponents,
        sourceDatestamp: String,
        destinationDatestamp: String,
        todayStartOfDay: DateInRegion,
        ekEventStore: EKEventStore,
        settings: Settings,
        skipSave: Bool = false
    ) -> Bool {
        if let eKEventContext = event.eKEventContext,
            let ekEvent = ekEventStore.getEkEvent(for: event)
        {
            // MARK: Event is a calendar event. Update the calendar record.

            guard ekEvent.calendar.allowsContentModifications else {
                return false
            }

            // Shift the start and end dates and save.
            ekEvent.startDate = ekEvent.startDate + days
            ekEvent.endDate = ekEvent.endDate + days

            eKEventContext.startDate = ekEvent.startDate
            eKEventContext.endDate = ekEvent.endDate

            if !ekEventStore.attemptUpdateEvent(ekEvent) {
                // The update failed. Skip this event.
                return false
            }
        }

        if let time = event.time {
            event.time = time + days
        }

        event.datestamp = destinationDatestamp

        // Place the event at the top of its new planner.
        _ = ensureValidPlannerEventPosition(
            for: event,
            sourceDatestamp: sourceDatestamp,
            todayStartOfDay: todayStartOfDay,
            settings: settings
        )

        if !skipSave {
            safeSave("shiftPlannerEvent shiftPlannerEvent")
        }

        return event.datestamp != sourceDatestamp
    }
}
