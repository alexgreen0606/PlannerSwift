//
//  CalendarEventToggler.swift
//  Planner
//
//  Created by Alex Green on 1/18/26.
//

import EventKit
import SwiftData
import SwiftUI

@MainActor
final class CalendarEventToggler {
    private let calendarSettings: CalendarSettings?

    init(calendarSettings: CalendarSettings?) {
        self.calendarSettings = calendarSettings
    }

    func isPlannerEventChecked(_ event: PlannerEvent) -> Bool {
        guard
            let settings = calendarSettings,
            let calendarEvent = event.calendarEvent
        else {
            return event.isChecked
        }

        return settings.checkedCalendarEventIds.contains(calendarEvent.eventIdentifier)
    }

    func toggleEvent(_ event: PlannerEvent) -> Bool {
        guard
            let settings = calendarSettings,
            let calendarEvent = event.calendarEvent
        else {
            return false
        }

        if settings.checkedCalendarEventIds.contains(
            calendarEvent.eventIdentifier
        ) {
            settings.checkedCalendarEventIds.remove(
                calendarEvent.eventIdentifier
            )
        } else {
            settings.checkedCalendarEventIds.insert(
                calendarEvent.eventIdentifier
            )
        }

        return true
    }
}
