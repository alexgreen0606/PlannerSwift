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
        matching query: PlannerSearchQuery
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

                } else if !searchingText && plannerEvent.isCompleted {

                    // Event is completed in the present or future and there is no text we are searching for.
                    // Exclude.
                    return false

                } else if let time = plannerEvent.time {

                    // Timed planner events that exist on or after today.
                    return time >= todayStartDate

                } else if let datestamp = plannerEvent.datestamp {

                    // Untimed planner events that exist on or after today.
                    return datestamp >= todaystamp

                } else {
                    return false
                }
            }
        }
    }

    func searchQueryScore(_ query: PlannerSearchQuery) -> Double? {
        if let calendarIdentifier = eKEventContext?.calendarIdentifier,
            query.isCalendarHidden(calendarId: calendarIdentifier)
        {
            // Calendar is hidden. Exclude.
            return nil
        }
        
        if !query.calendarIds.isEmpty && eKEventContext == nil {
            return nil
        }

        if let eKEventContext {
            if !query.containsDateRange(
                startDate: eKEventContext.startDate,
                endDate: eKEventContext.endDate
            ) {
                // Doesn't match the time range. Exclude.
                return nil
            }
        } else if let time {
            if !query.containsDate(time) {
                // Doesn't match the time range. Exclude.
                return nil
            }
        } else if let datestamp {
            if !query.containsDatestamp(datestamp) {
                // Doesn't match the time range. Exclude.
                return nil
            }
        }

        if query.text.isEmpty {
            if isCompleted && !query.past {
                return nil
            } else {
                // No search text and event is pending. Complete match!
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

        if score != 0.0 {
            // Title or location matches the search text. Include weighted score.
            return score
        }

        // Nothing matches the search query. Exclude.
        return nil
    }
}
