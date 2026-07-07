//
//  PlannerEvent+Search.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit
import SwiftDate

extension PlannerEvent {
    static func plannerEvents(
        matching query: SearchQuery
    ) -> Predicate<PlannerEvent> {
        let todayStartDate = query.todayStartOfDay.date
        let todaystamp = query.todayStartOfDay.datestamp
        let searchingText = !query.text.isEmpty

        if query.past {
            return #Predicate<PlannerEvent> { plannerEvent in
                if plannerEvent.eKEventContext != nil {

                    // Skip calendar events. These will be evaluated directly from the EKEventStore.
                    return false

                } else if let time = plannerEvent.time {

                    // Timed planner events that exist before today.
                    return time < todayStartDate

                } else if let datestamp = plannerEvent.datestamp {

                    // Untimed planner events that exist before today.
                    return datestamp < todaystamp

                } else {
                    return false
                }
            }
        } else {
            return #Predicate<PlannerEvent> { plannerEvent in
                if plannerEvent.eKEventContext != nil {

                    // Skip calendar events. These will be evaluated directly from the EKEventStore.
                    return false

                } else if let time = plannerEvent.time {

                    // Timed planner events that exist on or after today,
                    // are pending or we are searching for text.
                    return time >= todayStartDate
                        && (!plannerEvent.isCompleted || searchingText)

                } else if let datestamp = plannerEvent.datestamp {

                    // Untimed planner events that exist on or after today,
                    // are pending or we are searching for text.
                    return datestamp >= todaystamp
                        && (!plannerEvent.isCompleted || searchingText)

                } else {
                    return false
                }
            }
        }
    }

    func searchQueryScore(_ query: SearchQuery) -> Double? {
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

        if let eKEventContext {
            guard
                query.containsDateRange(
                    startDate: eKEventContext.startDate,
                    endDate: eKEventContext.endDate
                )
            else {
                // Doesn't match the time range. Exclude.
                return nil
            }
        } else if let time {
            guard query.containsDate(time) else {
                // Doesn't match the time range. Exclude.
                return nil
            }
        } else if let datestamp {
            guard query.containsDatestamp(datestamp) else {
                // Doesn't match the time range. Exclude.
                return nil
            }
        }

        if query.text.isEmpty {
            if isCompleted && !query.past {
                // No search text, event is complete, and in the present or future. Exclude.
                return nil
            } else {
                // No search text and event is pending or in the past. Include!
                return 1.0
            }
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

        // TODO: clean this up below
        var possibleDatestamps: [String] = []

        if let eKEventContext {
            possibleDatestamps = getSortedPossibleDatestamps(
                for: eKEventContext.startDate,
                ending: eKEventContext.endDate
            )
        } else if let time {
            possibleDatestamps = getSortedPossibleDatestamps(for: time)
        } else if let datestamp {
            possibleDatestamps = [datestamp]
        }

        // Scan every possible datestamp for a matching weekday or month.
        for datestamp in possibleDatestamps {
            // Scan this weekday for a match.
            if let weekdayScore = query.score(for: datestamp.weekday) {
                score += weekdayScore
            }

            // Scan this month for a match.
            if let monthDigit = Int(datestamp.monthDigit),
                let month = Month.from(number: monthDigit),
                let monthScore = query.score(for: month.label)
            {
                score += monthScore
            }
        }

        if score != 0.0 {
            // Title or location matches the search text. Include weighted score.
            return score
        }

        // Nothing matches the search query. Exclude.
        return nil
    }
}
