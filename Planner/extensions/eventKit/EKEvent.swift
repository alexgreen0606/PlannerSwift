//
//  EKEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import Fuse
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

    func spansOutsidePlannerDay(plannerDay: DateInRegion) -> Bool {
        let startOfNextDay = plannerDay + 1.days

        // Note: ending at the start of the next day should NOT be considered existing in that day.
        // This is how Apple's Calendar app behaves.
        return self.startDate < plannerDay.date
            || self.endDate > startOfNextDay.date
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? {
        guard let query else {
            // Include. No query set.
            return 1.0
        }

        if self.calendar.isHidden(
            filteredCalendarIds: query.filteredCalendarIds
        ) {
            // Exclude. Calendar is hidden.
            return nil
        }

        if !query.containsDateRange(
            startDate: self.startDate,
            endDate: self.endDate
        ) {
            // Exclude. Doesn't match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include. No search text.
            return 1.0
        }

        var score: Double = 0.0

        if let titleScore = query.score(for: self.title) {
            // Include. Title matches the search text.
            score += titleScore
        }

        if let location = self.location,
            self.location(storageEvent: nil) != nil,
            let locationScore = query.score(for: location)
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
