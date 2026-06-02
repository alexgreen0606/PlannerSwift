//
//  PlannerEvent+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension PlannerEvent {
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

    // MARK: - Location

    private func location(
        planner: Planner?,
        deviceLocation: Location?,
        settings: PlannerSettings
    )
        /// nil means the current device location is used and hasn't loaded yet.
        -> Location?
    {
        eventLocation(
            location: location,
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
    }

    func region(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> Region {
        location(
            planner: planner,
            deviceLocation: deviceLocation,
            settings: settings,
        )?.region ?? .local
    }

    func locationLabel(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> String {
        location(
            planner: planner,
            deviceLocation: deviceLocation,
            settings: settings
        )?.name ?? "Current Location"
    }

    // MARK: - Style

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = calendarEvent?.calendar {
            return calendar.color
        }

        return accentColor.color
    }

    // MARK: - Synchronization

    @MainActor
    func syncWithCalendarEvent(_ calendarEvent: EKEvent) {
        title = calendarEvent.title
        time = calendarEvent.startDate
        location = calendarEvent.location(
            existingPlannerEvent: self
        )

        calendarItemExternalIdentifier =
            calendarEvent.calendarItemExternalIdentifier
        occurrenceId = calendarEvent.occurrenceId

        // TODO: should I make routine variants here??

        self.calendarEvent = calendarEvent
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
        guard calendarItemExternalIdentifier == nil, location == nil else {
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
