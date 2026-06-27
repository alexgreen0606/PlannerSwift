//
//  PlannerEvent+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension PlannerEvent: PlannerEventLocationHelpers {
    static let gregorianCalendar = Calendar(identifier: .gregorian)

    static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    // MARK: - UI

    func tint(accentColor: AccentColor) -> Color {
        if let calendarColor = eKEventContext?.calendarColorHex.color {
            return calendarColor
        }

        return accentColor.color
    }

    func calendarSystemImageName(settings: PlannerSettings) -> String {
        if let calendar = eKEventContext?.ekEvent?.calendar {
            return calendar.systemImageName(settings: settings)
        }

        if let eKEventContext,
            let existing = settings.iconMap[eKEventContext.calendarIdentifier]
        {
            return existing
        }

        if title.localizedCaseInsensitiveContains("birthday") {
            return "birthday.cake.fill"
        }

        return "calendar"
    }

    // MARK: - Synchronization

    @MainActor
    func syncWithCalendarEvent(
        _ ekEvent: EKEvent
    ) {
        // Sync common data between planner and calendar events.
        title = ekEvent.title
        location = ekEvent.location(
            existingPlannerEvent: self
        )
        time = ekEvent.startDate
        
        routineEventRecordContext?.isVariant = true

        // Sync calendar-specific data.

        guard let eKEventContext else {
            // Note: This initializer automatically attaches the EKEventContext to the PlannerEvent.
            _ = EKEventContext(ekEvent: ekEvent, plannerEvent: self)
            return
        }

        eKEventContext.startDate = ekEvent.startDate
        eKEventContext.endDate = ekEvent.endDate
        eKEventContext.isAllDay = ekEvent.isAllDay

        eKEventContext.calendarItemExternalIdentifier =
            ekEvent.calendarItemExternalIdentifier
        eKEventContext.calendarIdentifier =
            ekEvent.calendar.calendarIdentifier
        eKEventContext.calendarColorHex =
            ekEvent.calendar.cgColor.hexString
        eKEventContext.calendarAllowsContentModifications =
            ekEvent.calendar.allowsContentModifications

        eKEventContext.birthdayContactIdentifier =
            ekEvent.birthdayContactIdentifier

        eKEventContext.ekEvent = ekEvent
    }

    @MainActor
    func syncWithRoutineEvent(on startOfDay: DateInRegion) {
        guard
            let routineEventRecordContext,
            !routineEventRecordContext.isVariant,
            let routineEventContext = routineEventRecordContext.routineEvent?
                .routineEventContext,
            routineEventRecordContext.syncedVersion
                != routineEventContext.version
        else {
            return
        }

        title = routineEventContext.title
        time = routineEventContext.date(on: startOfDay)

        routineEventRecordContext.syncedVersion = routineEventContext.version
    }

    @MainActor
    func updateRoutineVariance(
        in timeZone: TimeZone,
        settings: PlannerSettings
    ) {
        guard let routineEventRecordContext,
            let routineEventContext = routineEventRecordContext.routineEvent?
                .routineEventContext
        else {
            return
        }

        routineEventRecordContext.isVariant = !matches(
            routineEventContext,
            in: timeZone,
            settings: settings
        )
    }

    func matches(
        _ routineEvent: RoutineEventContext,
        in timeZone: TimeZone,
        settings: PlannerSettings
    ) -> Bool {
        guard eKEventContext == nil,
            location == nil,
            let originPlanner = routineEventRecordContext?.planner
        else {
            return false
        }

        // Title match.
        if title.trimmed != routineEvent.title.trimmed {
            return false
        }

        // Origin planner match.
        if let time {
            let originStartOfDay = originPlanner.startOfDay(settings: settings)

            if !time.belongsToPlanner(startOfDay: originStartOfDay) {
                return false
            }

        } else if datestamp != originPlanner.datestamp {
            return false
        }

        // Time match.

        var plannerCalendar = Self.gregorianCalendar
        plannerCalendar.timeZone = timeZone

        let eventComponents: DateComponents? = {
            guard let time else {
                return nil
            }

            return plannerCalendar.dateComponents(
                [.hour, .minute],
                from: time
            )
        }()

        let routineComponents: DateComponents? = {
            guard let routineEventTime = routineEvent.time else {
                return nil
            }

            return Self.utcCalendar.dateComponents(
                [.hour, .minute],
                from: routineEventTime
            )
        }()

        return eventComponents?.hour == routineComponents?.hour
            && eventComponents?.minute == routineComponents?.minute
    }
}
