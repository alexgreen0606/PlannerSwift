//
//  EKEvent+Search.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit

extension EKEvent {
    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? {
        guard let query else {
            // No search query. Complete match!
            return 1.0
        }

        if query.isCalendarHidden(calendarId: calendar.calendarIdentifier) {
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
        if let location,
            self.location() != nil,
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
