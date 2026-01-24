//
//  CalendarEventToggler.swift
//  Planner
//
//  Created by Alex Green on 1/18/26.
//

import EventKit
import SwiftData
import SwiftUI
import Combine

@MainActor
final class CalendarEventToggler {
    var calendarSettings: CalendarSettings? = nil

    func isPlannerEventChecked(_ event: PlannerEvent) -> Bool {
        guard
            let settings = calendarSettings,
            let calendarEvent = event.calendarEvent
        else {
            return event.isChecked
        }

        return settings.checkedCalendarEventIds.contains(calendarEvent.calendarItemExternalIdentifier)
    }

    func toggleEvent(_ event: PlannerEvent) -> Bool {
        guard
            let settings = calendarSettings,
            let calendarEvent = event.calendarEvent
        else {
            return false
        }

        if settings.checkedCalendarEventIds.contains(
            calendarEvent.calendarItemExternalIdentifier
        ) {
            settings.checkedCalendarEventIds.remove(
                calendarEvent.calendarItemExternalIdentifier
            )
        } else {
            settings.checkedCalendarEventIds.insert(
                calendarEvent.calendarItemExternalIdentifier
            )
        }

        return true
    }
}
