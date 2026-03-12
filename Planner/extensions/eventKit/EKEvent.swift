//
//  EKEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

// Clean

extension EKEvent {

    var transitionId: String {
        "\(String(describing: self.eventIdentifier))"
    }

    // Uniquely identifies occurrences of recurring events.
    // Changes anytime the date of the event changes.
    var occurrenceId: String? {
        guard
            hasRecurrenceRules,
            let externalId = calendarItemExternalIdentifier
        else {
            return nil
        }

        let dateInRegion = DateInRegion(startDate, region: .UTC)
        let startString = dateInRegion.toISO()

        return "\(externalId)_\(startString)"
    }

    func spansOutsidePlannerDay(plannerStartOfDay: DateInRegion) -> Bool {
        let startOfNextPlannerDay = plannerStartOfDay + 1.days

        return self.startDate < plannerStartOfDay.date
            || self.endDate > startOfNextPlannerDay.date
    }

    func location(
        storageEvent: PlannerEvent? = nil
    ) -> Location? {

        if let locationLabel = self.location,
            let structuredLocation = self.structuredLocation,
            let latitude = structuredLocation.geoLocation?.coordinate
                .latitude,
            let longitude = structuredLocation.geoLocation?.coordinate
                .longitude,
            let timeZone = self.timeZone
        {

            let newLocation = Location(
                name: locationLabel,
                latitude: latitude,
                longitude: longitude,
                timeZoneIdentifier: timeZone.identifier
            )

            guard let existingLocation = storageEvent?.location,
                existingLocation.coordinateKey == newLocation.coordinateKey
            else {
                return newLocation
            }

            // Priority 1: Re-use the location in storage as long as it matches the event's location.
            return existingLocation
        }

        return nil
    }

    // MARK: - Helper Functions

    private func region(fallback: Region) -> Region {
        if let timeZone = self.timeZone {
            return Region(
                calendar: fallback.calendar,
                zone: timeZone,
                locale: fallback.locale
            )
        } else {
            return fallback
        }
    }

}
