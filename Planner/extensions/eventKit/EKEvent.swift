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
        let startOfNextPlannerDay = plannerDay + 1.days

        return self.startDate < plannerDay.date
            || self.endDate > startOfNextPlannerDay.date
    }

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? {
        guard let query else {
            // Include when no query is set.
            return 1.0
        }

        if query.filterPast && self.startDate >= query.todayStartOfDay.date {
            // Exclude if it doesnt match the time range.
            return nil
        }

        if !query.filterPast && self.endDate < query.todayStartOfDay.date {
            // Exclude if it doesnt match the time range.
            return nil
        }

        if self.calendar.isHidden(
            filteredCalendarIds: query.filteredCalendarIds
        ) {
            // Exclude if the calendar is hidden.
            return nil
        }

        if query.text.isEmpty {
            // Include if there is no search text.
            return 1.0
        }
        
        var score = 0.0

        if let results = query.fuse.search(query.text, in: self.title),
           results.score <= FuseConstants.fuzzyThreshold
        {
            // Include if the title matches the search text.
            score = 1 - results.score
        }

        if let location = self.location,
           self.location(storageEvent: nil) != nil,
           let results = query.fuse.search(query.text, in: location),
            results.score <= FuseConstants.fuzzyThreshold
        {
            // Include if the location matches the search text.
            score += (1 - results.score)
        }
        
        if score != 0.0 {
            return score
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
