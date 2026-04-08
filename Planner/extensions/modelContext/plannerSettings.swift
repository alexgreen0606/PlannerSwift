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

    // MARK: - ENSURE

    @MainActor
    func ensurePlannerSettings(
        settings: [PlannerSettings]
    ) -> PlannerSettings {
        if let existing = settings.first {
            return existing
        }

        let newSettings = PlannerSettings()

        insert(newSettings)
        self.safeSave("plannerSettings.ensurePlannerSettings")

        return newSettings
    }

    // MARK: - UPDATE

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

}
