//
//  EKEvent+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate

extension EKEvent {
    var transitionId: String {
        "\(String(describing: eventIdentifier))"
    }

    /// Uniquely identifies occurrences of recurring events.
    /// Changes anytime the date of the event changes.
    var occurrenceId: String? {
        guard
            hasRecurrenceRules,
            let calendarItemExternalIdentifier
        else {
            return nil
        }

        let timeString = DateInRegion(startDate, region: .UTC).toISO()

        return "\(calendarItemExternalIdentifier)_\(timeString)"
    }

    func location(
        existingPlannerEvent: PlannerEvent? = nil
    ) -> Location? {
        if let locationLabel = location,
            let structuredLocation,
            let latitude = structuredLocation.geoLocation?.coordinate
                .latitude,
            let longitude = structuredLocation.geoLocation?.coordinate
                .longitude,
            let timeZone = timeZone
        {
            let newLocation = Location(
                name: locationLabel,
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: timeZone.identifier
            )

            guard let existingLocation = existingPlannerEvent?.location,
                existingLocation.coordinateId == newLocation.coordinateId
            else {
                return newLocation
            }

            // Location in storage matches the event's location. Continue using it.
            return existingLocation
        }

        return nil
    }

    /// Note: Ending at the start of the next day should NOT be considered existing in that day.
    /// This is how Apple's Calendar app behaves.
    func spansOutsidePlanner(startOfDay: DateInRegion) -> Bool {
        let startOfNextDay = startOfDay + 1.days

        return startDate < startOfDay.date
            || endDate > startOfNextDay.date
    }
}
