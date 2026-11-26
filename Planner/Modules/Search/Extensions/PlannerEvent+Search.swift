//
//  PlannerEvent+Search.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit
import SwiftDate

extension PlannerEvent {
    /// Note: Searches include completed events.
    static func searchablePlannerEvents(
        within bounds: PlannerBounds
    ) -> Predicate<PlannerEvent> {
        let minDatestamp = bounds.minStartOfDay.datestamp
        let maxDatestamp = bounds.maxStartOfDay.datestamp
        let minDate = bounds.minStartOfDay.date
        let endOfBounds = bounds.endOfBounds

        return #Predicate<PlannerEvent> { plannerEvent in
            if plannerEvent.eKEventContext != nil {

                // Skip calendar events. These will be evaluated directly from the EKEventStore.
                return false

            } else if let time = plannerEvent.time {

                // Timed planner events that exist within the bounds.
                return time >= minDate && time < endOfBounds

            } else if let datestamp = plannerEvent.datestamp {

                // Untimed planner events that exist within the bounds.
                return datestamp >= minDatestamp && datestamp <= maxDatestamp

            } else {
                return false
            }
        }
    }

    func searchQueryScore(
        _ query: PlannerSearchQuery,
        /// Used to determine if event's planner matches the query.
        in plannerDatestamp: String
    ) -> Double? {
        if !query.calendarIds.isEmpty {
            guard
                let calendarIdentifier = eKEventContext?.calendarIdentifier,
                !query.isCalendarHidden(calendarId: calendarIdentifier)
            else {
                // Filtering by calendar events and this isn't a calendar event
                // or its calendar is hidden. Exclude.
                return nil
            }
        }

        if query.text.isEmpty {
            // No search text. Include! (Searches include completed events.)
            return 1.0
        }

        var score = 0.0

        // Scan the title for a match.
        if let titleScore = query.score(for: title) {
            score += titleScore
        }

        // Scan the location for a match.
        if let location = location,
            let locationScore = query.score(for: location.name)
        {
            score += locationScore
        }

        // Scan the planner for a match when searching calendar events.
        // This helps us pin-point calendar events in certain months or weekdays.
        if !query.calendarIds.isEmpty, eKEventContext != nil {
            // Scan planner weekday for a match.
            if let weekdayScore = query.score(for: plannerDatestamp.weekday) {
                score += weekdayScore
            }

            // Scan planner month for a match.
            if let monthDigit = Int(plannerDatestamp.monthDigit),
                let month = Month.from(number: monthDigit),
                let monthScore = query.score(for: month.label)
            {
                score += monthScore
            }
        }

        if score != 0.0 {
            // Title, location, weekday, or month matches the search text. Include weighted score.
            return score
        }

        // Nothing matches the search query. Exclude.
        return nil
    }
}
