//
//  CalendarSettingsExtension.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import EventKit

extension CalendarSettings {

    func isPlannerEventChecked(_ event: PlannerEvent) -> Bool {
        guard let calendarEvent = event.calendarEvent
        else {
            return event.isChecked
        }

        return self.checkedCalendarEventIds.contains(
            calendarEvent.calendarItemExternalIdentifier
        )
    }

    // Returns true if the event was toggled, else false.
    func toggleEvent(_ event: PlannerEvent) -> Bool {
        guard let calendarEvent = event.calendarEvent
        else {
            return false
        }

        if self.checkedCalendarEventIds.contains(
            calendarEvent.calendarItemExternalIdentifier
        ) {
            self.checkedCalendarEventIds.remove(
                calendarEvent.calendarItemExternalIdentifier
            )
        } else {
            self.checkedCalendarEventIds.insert(
                calendarEvent.calendarItemExternalIdentifier
            )
        }

        return true
    }
}
