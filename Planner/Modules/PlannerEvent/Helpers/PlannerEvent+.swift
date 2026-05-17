//
//  PlannerEventExtension.swift
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
    var isRoutineVariant: Bool {
        routineEventVariant != nil && routineEvent != nil
    }

    func isRoutineVariant(notFrom planner: Planner) -> Bool {
        guard let routineEventVariant, routineEvent != nil else {
            return false
        }
        return routineEventVariant.planner !== planner
    }

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
        isCompleted || isCanceled
    }

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
            storageEvent: self
        )
        self.calendarEvent = calendarEvent
        calendarItemExternalIdentifier =
            calendarEvent.calendarItemExternalIdentifier
        occurrenceId = calendarEvent.occurrenceId
    }

    @MainActor
    func syncWithRoutineEvent(
        _ routineEvent: RoutineEvent,
        on plannerDay: DateInRegion
    ) {
        guard !isRoutineVariant else {
            return
        }

        title = routineEvent.title

        if let time = routineEvent.date(in: plannerDay) {
            self.time = time
        } else {
            time = nil
        }

        self.routineEvent = routineEvent
    }

    func matches(
        _ routineEvent: RoutineEvent,
        in timeZone: TimeZone
    ) -> Bool {
        guard calendarItemExternalIdentifier == nil, location == nil else {
            return false
        }

        let calendar = Calendar(identifier: .gregorian)

        var plannerCalendar = calendar
        plannerCalendar.timeZone = timeZone

        var utcCalendar = calendar
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        let eventComponents: DateComponents? = {
            guard let time = self.time else {
                return nil
            }
            return plannerCalendar.dateComponents(
                [.hour, .minute],
                from: time
            )
        }()
        let routineComponents: DateComponents? = {
            guard let time = routineEvent.time else {
                return nil
            }
            return utcCalendar.dateComponents([.hour, .minute], from: time)
        }()

        return title == routineEvent.title
            && eventComponents?.hour == routineComponents?.hour
            && eventComponents?.minute == routineComponents?.minute
    }

    // MARK: - View Builders

    @ViewBuilder
    func timeAdornment(
        in plannerRegion: Region,
        accentColor: AccentColor,
        scale: Double = 1,
        openEventSheet: (() -> Void)?
    ) -> some View {
        if let time = time {
            TimeView(
                timeInRegion: DateInRegion(time, region: plannerRegion),
                color: tint(accentColor: accentColor),
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
        let eventLocationLabel = locationLabel(
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
            if isTimeZoneDifferent, let time {
                return DateInRegion(
                    time,
                    region: eventRegion
                ).timeWithTimezone
            }
            return nil
        }()

        EventLocationAdornmentView(
            iconConfig: IconConfig(
                name: "mappin.and.ellipse",
                primaryColor: tint(accentColor: accentColor)
            ),
            locationLabel: locationAdornment,
            timeLabel: timeAdornment,
            openEventSheet: openEventSheet
        )
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? // nil means the event doesn't match the query
    {
        guard let query else {
            // Query not set. Include if unchecked.
            if isChecked {
                return nil
            } else {
                return 1.0
            }
        }

        if let calendarEvent = calendarEvent,
           calendarEvent.calendar.isHidden(
               filteredCalendarIds: query.filteredCalendarIds
           )
        {
            // Exclude. Calendar is hidden.
            return nil
        }

        if let time {
            if !query.containsDate(time) {
                // Exclude. Doesn't match the time range.
                return nil
            }
        } else if let datestamp {
            if !query.containsDatestamp(datestamp) {
                // Exclude. Doesn't match the time range.
                return nil
            }
        }

        if query.text.isEmpty {
            // Search text not set. Inclide if unchecked.
            if isChecked {
                return nil
            } else {
                return 1.0
            }
        }

        var score = 0.0

        if let titleScore = query.score(for: title) {
            // Include. Title matches the search text.
            score += titleScore
        }

        if let location = location,
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
}
