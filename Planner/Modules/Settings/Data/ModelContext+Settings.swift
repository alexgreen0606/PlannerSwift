//
//  ModelContext+Settings.swift
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
        settings: [Settings]
    ) {
        if settings.first != nil {
            return
        }

        insert(Settings())
        safeSave("settings ensurePlannerSettings")
    }

    // MARK: - UPDATE

    @MainActor
    func updateHomeLocation(
        in settings: Settings,
        to location: Location?
    ) {
        settings.homeLocation = location
        safeSave("settings updateHomeLocation")
    }

    @MainActor
    func updateCalendarIcon(
        in settings: Settings,
        for calendar: EKCalendar,
        to systemImageName: String
    ) {
        settings.iconMap[
            calendar.calendarIdentifier
        ] = systemImageName

        safeSave("settings updateCalendarIcon")
    }

    @MainActor
    func toggleCalendarVisibility(
        in settings: Settings,
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

        safeSave("settings toggleCalendarVisibility")
    }
}
