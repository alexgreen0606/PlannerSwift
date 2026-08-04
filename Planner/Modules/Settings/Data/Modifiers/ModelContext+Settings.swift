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

extension ModelContext {
    // MARK: - ENSURE / DEDUPLICATION

    @MainActor
    func ensureSettings(
        settings: [Settings]
    ) {
        switch settings.count {
        case 0:
            insert(Settings())
            safeSave("ModelContext+Settings ensurePlannerSettings")

        case 1:
            break

        default:
            deduplicateSettings(settingsList: settings)
        }
    }

    @MainActor
    private func deduplicateSettings(
        settingsList: [Settings]
    ) {
        guard let merged = settingsList.first else {
            return
        }

        for settings in settingsList.dropFirst() {
            // Merge calendar icons.
            merged.calendarIconMap.merge(settings.calendarIconMap) { old, _ in
                old
            }

            // Merge hidden calendars.
            merged.hiddenCalendarIds.formUnion(settings.hiddenCalendarIds)

            // Merge home location.
            if let location = settings.homeLocation, merged.homeLocation == nil
            {
                merged.homeLocation = location
                location.settings = merged
                settings.homeLocation = nil
            }

            delete(settings)
        }

        safeSave("ModelContext+Settings deduplicateSettings")
    }

    // MARK: - UPDATE

    @MainActor
    func updateHomeLocation(
        in settings: Settings,
        to location: Location?,
        plannerService: PlannerService
    ) {
        settings.homeLocation = location
        safeSave("ModelContext+Settings updateHomeLocation")

        plannerService.syncVisiblePlanners()
    }

    @MainActor
    func updateCalendarIcon(
        in settings: Settings,
        for calendar: EKCalendar,
        to systemImageName: String
    ) {
        settings.calendarIconMap[
            calendar.calendarIdentifier
        ] = systemImageName

        safeSave("ModelContext+Settings updateCalendarIcon")
    }

    @MainActor
    func toggleCalendarVisibility(
        in settings: Settings,
        for calendar: EKCalendar,
        plannerService: PlannerService
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

        safeSave("ModelContext+Settings toggleCalendarVisibility")
        
        plannerService.refreshCalendar()
    }
}
