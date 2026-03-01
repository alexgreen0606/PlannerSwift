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

    @MainActor
    func buildCalendarPlannerEvents(
        calendarEvents: [EKEvent],
        storageEvents: [PlannerEvent],
        startOfDay: DateInRegion
    ) -> [PlannerEvent] {

        var plannerEvents: [PlannerEvent] = []
        var newEvents: [EKEvent] = []

        for calEvent in calendarEvents {

            // Use the user-defined sort date if one exists.
            if let customSortDate = self.calendarSortDateMap[
                calEvent.calendarItemExternalIdentifier
            ] {
                // Build the dummy event for UI representation. No persistence to storage.
                let plannerEvent = PlannerEvent(
                    date: calEvent.startDate,
                    calendarEvent: calEvent,
                    sortIndex: 0
                )
                plannerEvent.hasTime = true
                plannerEvent.sortDate = customSortDate
                plannerEvents.append(plannerEvent)
            } else {
                newEvents.append(calEvent)
            }

        }

        var sortedExisting = (storageEvents + plannerEvents).sorted {
            $0.sortDate < $1.sortDate
        }

        let sortedNewEvents = newEvents.sorted { $0.startDate > $1.startDate }

        for newEvent in sortedNewEvents {

            let newSortDate = generateSortDate(
                startOfDay: startOfDay,
                index: 0,
                events: sortedExisting,
                settings: self
            )

            let plannerEvent = PlannerEvent(
                date: newEvent.startDate,
                calendarEvent: newEvent,
                sortIndex: 0
            )
            plannerEvent.hasTime = true
            plannerEvent.sortDate = newSortDate
            plannerEvents.append(plannerEvent)
            sortedExisting.insert(plannerEvent, at: 0)
            
            self.calendarSortDateMap[newEvent.calendarItemExternalIdentifier] = newSortDate
        }

        return plannerEvents
    }
}
