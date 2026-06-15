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

    var transitionId: String {
        stableId.uuidString
    }

    var isRoutineVariant: Bool {
        routineEventVariant != nil && routineEvent != nil
    }

    func isEventChip(on startOfDay: DateInRegion) -> Bool {
        guard let calendarContext else {
            return false
        }

        let startOfNextDay = startOfDay + 1.days
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date

        if calendarContext.isAllDay {
            return calendarContext.startDate < plannerEnd
                && calendarContext.endDate >= plannerStart
        }

        return calendarContext.startDate < plannerStart
            && calendarContext.endDate >= plannerStart
            || calendarContext.endDate >= plannerEnd
                && calendarContext.startDate < plannerEnd
    }

    // MARK: - UI

    func tint(accentColor: AccentColor) -> Color {
        if let calendarColor = calendarContext?.calendarColorHex.color {
            return calendarColor
        }

        return accentColor.color
    }

    func calendarSystemImageName(settings: PlannerSettings) -> String {
        if let calendar = calendarContext?.ekEvent?.calendar {
            return calendar.systemImageName(settings: settings)
        }

        if let calendarContext,
            let existing = settings.iconMap[calendarContext.calendarId]
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
        if let existingContext = calendarContext {
            existingContext.startDate = ekEvent.startDate
            existingContext.endDate = ekEvent.endDate
            existingContext.isAllDay = ekEvent.isAllDay

            existingContext.calendarItemExternalIdentifier =
                ekEvent.calendarItemExternalIdentifier
            existingContext.calendarId =
                ekEvent.calendar.calendarIdentifier
            existingContext.calendarColorHex =
                ekEvent.calendar.cgColor.hexString
            existingContext.editable =
                ekEvent.calendar.allowsContentModifications

            existingContext.birthdayContactIdentifier =
                ekEvent.birthdayContactIdentifier

            existingContext.ekEvent = ekEvent
        } else {
            calendarContext = CalendarEventContext(ekEvent: ekEvent)
        }
    }

    @MainActor
    func syncWithRoutineEvent(
        _ routineEvent: RoutineEvent,
        on startOfDay: DateInRegion
    ) {
        guard !isRoutineVariant else {
            return
        }

        title = routineEvent.title
        time = routineEvent.date(in: startOfDay)

        self.routineEvent = routineEvent
    }

    func matches(
        _ routineEvent: RoutineEvent,
        in timeZone: TimeZone,
        originPlanner: Planner,
        settings: PlannerSettings
    ) -> Bool {
        guard calendarContext == nil, location == nil else {
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
