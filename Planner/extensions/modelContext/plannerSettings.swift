//
//  plannerSettings.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    @MainActor
    func ensurePlannerSettings(
        settings: [PlannerSettings]
    ) {
        if settings.first != nil {
            return
        }

        let newSettings = PlannerSettings()
        insert(newSettings)

        self.safeSave("plannerSettings.ensurePlannerSettings")
    }

    @MainActor
    func updateHomeLocation(
        in settings: PlannerSettings,
        to location: Location?
    ) {

        settings.homeLocation = location

        self.safeSave("plannerSettings.updateHomeLocation")
    }

    @MainActor
    func updateCalendarIcon(
        in settings: PlannerSettings,
        for calendar: EKCalendar,
        to systemImageName: String
    ) {

        settings.iconMap[
            calendar.calendarIdentifier
        ] = systemImageName

        self.safeSave("plannerSettings.updateCalendarIcon")
    }

    @MainActor
    func toggleCalendarVisibility(
        in settings: PlannerSettings,
        for calendar: EKCalendar
    ) {
        if settings.hiddenCalendarIds.contains(
            calendar.calendarIdentifier
        ) {
            settings.hiddenCalendarIds.remove(
                calendar.calendarIdentifier
            )
        } else {
            settings.hiddenCalendarIds.insert(
                calendar.calendarIdentifier
            )
        }

        self.safeSave("plannerSettings.toggleCalendarVisibility")
    }

    @MainActor
    func deleteStaleCalendarEvents(
        in settings: PlannerSettings,
        with eventIds: Set<String>
    ) {

        // TODO: implement

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

}
