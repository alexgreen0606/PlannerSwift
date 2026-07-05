//
//  DraftPlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/24/26.
//

import EventKit
import SwiftDate
import SwiftUI

struct DraftPlannerEvent: PlannerEventLocationHelpers {
    var title: String = ""
    var date: Date = Date()
    var hasTime: Bool = false
    var location: Location? = nil
    var ekEvent: EKEvent? = nil

    // MARK: New Planner Event
    init() {
        // Initialize time down to the start of this hour.
        date =
            DateInRegion(Date(), region: .local)
            .dateAtStartOf(.hour)
            .date
    }

    // MARK: Existing Planner Event
    init(
        plannerEvent: PlannerEvent,
        planner: Planner,
        ekEventStore: EKEventStore,
        settings: Settings
    ) {
        title = plannerEvent.title
        location = plannerEvent.location

        if let ekEvent = ekEventStore.getEkEvent(for: plannerEvent) {
            // Sync draft with calendar event.

            date = ekEvent.startDate
            hasTime = true
            self.ekEvent = ekEvent

        } else {
            if let time = plannerEvent.time {
                date = time
                hasTime = true

            } else {
                // Event is untimed. Default to a user-friendly time.

                let now = DateInRegion(Date(), region: .local)

                let thisTimeOnPlannerDay =
                    planner.startOfDay(settings: settings).dateBySet(
                        hour: now.hour,
                        min: 0,
                        secs: 0
                    ) ?? now

                // Round the time down to the start of the hour.
                date =
                    thisTimeOnPlannerDay
                    .dateAtStartOf(.hour)
                    .date
            }
        }
    }
}
