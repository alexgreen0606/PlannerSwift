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

    var isRoutineVariant: Bool {
        routineEventVariant != nil
    }

    var routineEvent: RoutineEvent? {
        routineEventRecordContext?.routineEvent
    }

    var routineEventContext: RoutineEventContext? {
        routineEventRecordContext?.routineEvent?.routineEventContext
    }

    var routineEventVariant: RoutineEventVariant? {
        routineEventRecordContext?.variant
    }

    func isEventChip(on startOfDay: DateInRegion) -> Bool {
        guard let eKEventContext else {
            return false
        }

        let startOfNextDay = startOfDay + 1.days
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date

        if eKEventContext.isAllDay {
            return eKEventContext.startDate < plannerEnd
                && eKEventContext.endDate >= plannerStart
        }

        return eKEventContext.startDate < plannerStart
            && eKEventContext.endDate >= plannerStart
            || eKEventContext.endDate >= plannerEnd
                && eKEventContext.startDate < plannerEnd
    }

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

        // Sync calendar-specific data.
        if let existingContext = eKEventContext {
            existingContext.startDate = ekEvent.startDate
            existingContext.endDate = ekEvent.endDate
            existingContext.isAllDay = ekEvent.isAllDay

            existingContext.calendarItemExternalIdentifier =
                ekEvent.calendarItemExternalIdentifier
            existingContext.calendarIdentifier =
                ekEvent.calendar.calendarIdentifier
            existingContext.calendarColorHex =
                ekEvent.calendar.cgColor.hexString
            existingContext.calendarAllowsContentModifications =
                ekEvent.calendar.allowsContentModifications

            existingContext.birthdayContactIdentifier =
                ekEvent.birthdayContactIdentifier

            existingContext.ekEvent = ekEvent
        } else {
            // Note: This initializer automatically attaches the EKEventContext to the PlannerEvent
            _ = EKEventContext(ekEvent: ekEvent, plannerEvent: self)
        }
    }

    @MainActor
    func syncWithRoutineEvent(
        _ routineEvent: RoutineEvent,
        on startOfDay: DateInRegion
    ) {
        guard !isRoutineVariant,
            let routineEventContext = routineEvent.routineEventContext
        else {
            return
        }

        title = routineEventContext.title
        time = routineEventContext.date(on: startOfDay)

        if let existingContext = routineEventRecordContext {
            existingContext.syncedVersion = routineEventContext.version
        } else {
            // Note: This initializer automatically attaches the RoutineEventRecordContext to the PlannerEvent
            let _ = RoutineEventRecordContext(
                routineEvent: routineEvent,
                plannerEvent: self
            )
        }
    }

    func matches(
        _ routineEvent: RoutineEventContext,
        in timeZone: TimeZone,
        originPlanner: Planner,
        settings: PlannerSettings
    ) -> Bool {
        guard eKEventContext == nil, location == nil else {
            return false
        }

        // MARK: Title match.
        if title.trimmed != routineEvent.title.trimmed {
            return false
        }

        // MARK: Origin planner match.
        if let time {
            let originStartOfDay = originPlanner.startOfDay(settings: settings)

            if !time.belongsToPlanner(startOfDay: originStartOfDay) {
                return false
            }

        } else if datestamp != originPlanner.datestamp {
            return false
        }

        // MARK: Time match.

        var plannerCalendar = Self.gregorianCalendar
        plannerCalendar.timeZone = timeZone

        let eventComponents: DateComponents? = {
            guard let eventTime = self.time else {
                return nil
            }

            return plannerCalendar.dateComponents(
                [.hour, .minute],
                from: eventTime
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
