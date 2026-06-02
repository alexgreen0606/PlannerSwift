//
//  PlannerEvent+Search.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit

extension PlannerEvent {
    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double?  // nil means the event doesn't match the query
    {
        guard let query else {
            // Query not set. Include if unchecked.
            if isCompleted {
                return nil
            } else {
                return 1.0
            }
        }

        if let calendarEvent = calendarEvent,
            calendarEvent.calendar.isHidden(
                filteredCalendarIds: query.calendarIds
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
            if isCompleted {
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
