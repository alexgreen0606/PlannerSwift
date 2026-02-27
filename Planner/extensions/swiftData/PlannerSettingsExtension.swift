//
//  PlannerSettingsExtension.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import EventKit
import SwiftDate
import SwiftUI

extension PlannerSettings {

    var homeRegion: Region {
        homeLocation?.region ?? .local
    }
    
    // Only ever nil if the device location is loading.
    func validHomeLocation(deviceLocation: Location?) -> Location? {
        homeLocation ?? deviceLocation
    }

    func homeLocationLabel(localCityName: String) -> String {
        homeLocation?.name ?? localCityName
    }

    var homeLocationIconConfig: IconConfig {
        IconConfig(
            name: homeLocation != nil ? "house" : "location"
        )
    }

    func isPlannerEventChecked(_ event: PlannerEvent) -> Bool {
        guard let calendarEvent = event.calendarEvent
        else {
            return event.isChecked
        }

        return isCalendarEventChecked(calendarEvent)
    }

    func isCalendarEventChecked(_ event: EKEvent) -> Bool {
        self.checkedCalendarEventIds.contains(
            event.calendarItemExternalIdentifier
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

    // Note: May want to consider adding events with a chronological sort.
    func buildCalendarPlannerEvents(
        calendarEvents: [EKEvent]
    ) -> [PlannerEvent] {

        var plannerEvents: [PlannerEvent] = []

        for calEvent in calendarEvents {

            // Build the dummy event for UI representation. No persistence to storage.
            let plannerEvent = PlannerEvent(
                date: calEvent.startDate,
                calendarEvent: calEvent,
                sortIndex: 0
            )
            plannerEvent.hasTime = true

            // Use the user-defined sort date if one exists.
            if let customSortDate = self.calendarSortDateMap[
                calEvent.calendarItemExternalIdentifier
            ] {
                plannerEvent.sortDate = customSortDate
            } else {
                self.calendarSortDateMap[
                    calEvent.calendarItemExternalIdentifier
                ] = calEvent.startDate
            }

            plannerEvents.append(plannerEvent)

        }

        return plannerEvents
    }
}
