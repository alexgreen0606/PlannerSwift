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
    var notes: String = ""
    var date: Date = Date()
    var hasTime: Bool = false
    var location: Location? = nil
    var isFlagged: Bool = false
    var ekEvent: EKEvent? = nil

    /// Creates a draft for a brand new event.
    init() {
        // Initialize time down to the start of this hour.
        date =
            DateInRegion(Date(), region: .local)
            .dateAtStartOf(.hour)
            .date
    }

    /// Builds a Planner draft from an existing planner event.
    init(
        plannerEvent: PlannerEvent,
        planner: Planner,
        ekEventStore: EKEventStore,
        settings: Settings
    ) {
        title = plannerEvent.title
        notes = plannerEvent.notes
        location = plannerEvent.location
        isFlagged = plannerEvent.isFlagged

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

    /// Builds a Planner draft from a calendar event (used by "Remove from Calendar").
    /// Note: `EKEventEditViewController` doesn't expose unsaved edits, so this reads the event's stored values.
    init(ekEvent: EKEvent) {
        self.init()

        title = ekEvent.title ?? ""
        notes = ekEvent.notes ?? ""
        date = ekEvent.startDate
        hasTime = !ekEvent.isAllDay
        location = ekEvent.location()
    }
}

// MARK: - Helper Extension

extension DraftPlannerEvent {
    /// Applies this draft to a calendar event (used by "Add to Calendar").
    /// When `sourceEkEvent` is nil, a new calendar event is created.
    func makeEkEvent(
        sourceEkEvent: EKEvent?,
        ekEventStore: EKEventStore,
        timeZone: TimeZone
    ) -> EKEvent {
        let ekEvent = sourceEkEvent ?? EKEvent(eventStore: ekEventStore)

        if sourceEkEvent == nil {
            ekEvent.calendar = ekEventStore.defaultCalendarForNewEvents
        }

        // Migrate event location into the calendar event.
        if let location {
            ekEvent.location = location.name

            ekEvent.structuredLocation = EKStructuredLocation(
                title: location.name
            )

            ekEvent.structuredLocation?.geoLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
        }

        ekEvent.title = title.trimmed
        ekEvent.notes = notes.trimmed.nilIfEmpty

        ekEvent.isAllDay = false
        ekEvent.startDate = date
        ekEvent.endDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: date
        )
        ekEvent.timeZone = timeZone

        return ekEvent
    }
}
