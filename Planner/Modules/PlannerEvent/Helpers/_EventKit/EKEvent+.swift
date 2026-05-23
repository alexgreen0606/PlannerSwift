//
//  EKEvent+.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import Fuse
import SwiftDate
import SwiftUI

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

        let dateInRegion = DateInRegion(startDate, region: .UTC)
        let startString = dateInRegion.toISO()

        return "\(calendarItemExternalIdentifier)_\(startString)"
    }

    func location(
        storageEvent: PlannerEvent? = nil
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

            guard let existingLocation = storageEvent?.location,
                  existingLocation.coordinateKey == newLocation.coordinateKey
            else {
                return newLocation
            }

            // Location in storage matches the event's location. Re-use it.
            return existingLocation
        }

        return nil
    }

    func spansOutsidePlannerDay(_ plannerDay: DateInRegion) -> Bool {
        let startOfNextDay = plannerDay + 1.days

        // Note: Ending at the start of the next day should NOT be considered existing in that day.
        // This is how Apple's Calendar app behaves.
        return startDate < plannerDay.date
            || endDate > startOfNextDay.date
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? {
        guard let query else {
            // No search query. Complete match!
            return 1.0
        }

        if calendar.isHidden(
            filteredCalendarIds: query.calendarIds
        ) {
            // Calendar is hidden. Exclude.
            return nil
        }

        if !query.containsDateRange(
            startDate: startDate,
            endDate: endDate
        ) {
            // Doesn't match the time range. Exclude.
            return nil
        }

        if query.text.isEmpty {
            // No search text. Complete match!
            return 1.0
        }

        var score = 0.0

        // Scan the title for a match.
        if let titleScore = query.score(for: title) {
            score += titleScore
        }

        // Scan the location for a match.
        if let location = location,
           self.location(storageEvent: nil) != nil,
           let locationScore = query.score(for: location)
        {
            score += locationScore
        }

        if score != 0.0 {
            // Title or location matches the search text. Include weighted score.
            return score
        }

        // Nothing matches the search query. Exclude.
        return nil
    }
}
