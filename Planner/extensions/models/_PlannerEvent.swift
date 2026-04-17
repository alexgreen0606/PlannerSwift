//
//  _PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import Fuse
import SwiftDate
import SwiftUI

// Clean

extension PlannerEvent {

    // MARK: - Location Variables

    private func location(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    )
        // nil means the current device location is used and hasn't loaded yet.
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
            settings: settings,
            deviceLocation: deviceLocation
        )?.region ?? .local
    }

    func locationLabel(
        planner: Planner?,
        settings: PlannerSettings,
        deviceLocation: Location?
    ) -> String {
        location(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )?.name ?? "Current Location"
    }

    // MARK: - Style Variables

    var isChecked: Bool {
        self.isCompleted || self.isCanceled
    }

    func tint(accentColor: AccentColor) -> Color {
        if let calendar = self.calendarEvent?.calendar {
            return calendar.color
        }
        return accentColor.color
    }

    // MARK: - Synchronization

    @MainActor
    func syncWithCalendarEvent(_ calendarEvent: EKEvent) {
        self.title = calendarEvent.title
        self.date = calendarEvent.startDate
        self.location = calendarEvent.location(
            storageEvent: self
        )
        self.hasTime = true
        self.calendarEvent = calendarEvent
        self.calendarItemExternalIdentifier =
            calendarEvent.calendarItemExternalIdentifier
        self.occurrenceId = calendarEvent.occurrenceId

        // Ensure events never link to routines when they are on the calendar.
        self.isRoutineEventException = true
    }

    @MainActor
    func syncWithRoutineEvent(
        _ routineEvent: RoutineEvent,
        on plannerDay: DateInRegion
    ) {
        guard !self.isRoutineEventException,
            self.calendarItemExternalIdentifier == nil
        else { return }

        self.title = routineEvent.title

        if let time = routineEvent.date(in: plannerDay) {
            self.date = time
            self.hasTime = true
        } else {
            self.hasTime = false
        }

        self.routineEvent = routineEvent
    }

    @MainActor
    func validateRoutineEventException(in timeZone: TimeZone) {
        if let routineEvent = self.routineEvent {
            // Mark the routine exception flag based on its match with the parent.
            self.isRoutineEventException = !self.matches(
                routineEvent,
                in: timeZone
            )
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    func timeAdornment(
        in plannerRegion: Region,
        accentColor: AccentColor,
        scale: Double = 1,
        openEventSheet: (() -> Void)?
    ) -> some View {
        if self.hasTime {
            TimeView(
                timeInRegion: DateInRegion(self.date, region: plannerRegion),
                color: self.tint(accentColor: accentColor),
                scale: scale,
                openEventSheet: openEventSheet
            )
        }
    }

    @ViewBuilder
    func locationAdornment(
        in planner: Planner,
        settings: PlannerSettings,
        deviceLocation: Location?,
        accentColor: AccentColor,
        openEventSheet: @escaping () -> Void
    ) -> some View {

        // Planner Info.
        let plannerRegion = planner.region(settings: settings)
        let plannerTimeZoneIdentifier = plannerRegion.timeZone.identifier
        let plannerLocationLabel = planner.locationLabel(
            settings: settings,
            deviceLocation: deviceLocation
        )

        // Event Info.
        let eventRegion = region(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )
        let eventTimeZoneIdentifier = eventRegion.timeZone.identifier
        let eventLocationLabel = self.locationLabel(
            planner: planner,
            settings: settings,
            deviceLocation: deviceLocation
        )

        let isLocationLabelDifferent =
            eventLocationLabel != plannerLocationLabel
        let isTimeZoneDifferent =
            eventTimeZoneIdentifier != plannerTimeZoneIdentifier

        // Assemble the event labels if they differ from the planner.

        let locationAdornment: String? =
            isLocationLabelDifferent ? eventLocationLabel : nil

        let timeAdornment: String? = {
            if isTimeZoneDifferent, hasTime {
                return DateInRegion(
                    date,
                    region: eventRegion
                ).timeWithTimezone
            }
            return nil
        }()

        EventLocationAdornmentView(
            iconConfig: IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: self.tint(accentColor: accentColor)
            ),
            locationLabel: locationAdornment,
            timeLabel: timeAdornment,
            openEventSheet: openEventSheet
        )
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double?  // nil means the event doesn't match the query
    {
        guard let query else {
            // Query not set. Include if unchecked.
            if self.isChecked {
                return nil
            } else {
                return 1.0
            }
        }

        if let calendarEvent = self.calendarEvent,
            calendarEvent.calendar.isHidden(
                filteredCalendarIds: query.filteredCalendarIds
            )
        {
            // Exclude. Calendar is hidden.
            return nil
        }

        if !query.containsDate(self.date) {
            // Exclude. Doesn't match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Search text not set. Inclide if unchecked.
            if self.isChecked {
                return nil
            } else {
                return 1.0
            }
        }

        var score = 0.0

        if let titleScore = query.score(for: self.title) {
            // Include. Title matches the search text.
            score += titleScore
        }

        if let location = self.location,
            let locationScore = query.score(for: location.name)
        {
            // Include. Location matches the search text.
            score += locationScore
        }

        if score != 0.0 {
            return score
        }

        return nil
    }

    // MARK: - Helpers

    private func matches(
        _ routineEvent: RoutineEvent,
        in timeZone: TimeZone
    ) -> Bool {
        let calendar = Calendar(identifier: .gregorian)

        var plannerCalendar = calendar
        plannerCalendar.timeZone = timeZone

        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let eventComponents: DateComponents? = {
            guard self.hasTime else {
                return nil
            }
            return plannerCalendar.dateComponents(
                [.hour, .minute],
                from: self.date
            )
        }()
        let routineComponents: DateComponents? = {
            guard let time = routineEvent.time else {
                return nil
            }
            return utcCalendar.dateComponents([.hour, .minute], from: time)
        }()

        return self.title == routineEvent.title
            && eventComponents?.hour == routineComponents?.hour
            && eventComponents?.minute == routineComponents?.minute
            && self.location == nil
            && self.calendarItemExternalIdentifier == nil
    }

}
