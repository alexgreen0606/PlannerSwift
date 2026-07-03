//
//  EKEvent+Search.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit

extension EKEvent {
    func searchQueryScore(_ query: SearchQuery) -> Double? {
        guard !query.isCalendarHidden(calendarId: calendar.calendarIdentifier) else{
            // Calendar is hidden. Exclude.
            return nil
        }

        guard query.containsDateRange(
            startDate: startDate,
            endDate: endDate
        ) else {
            // Doesn't match the time range. Exclude.
            return nil
        }

        if query.text.isEmpty {
            // No search text. Include!
            return 1.0
        }

        var score = 0.0

        // Scan the title for a match.
        if let titleScore = query.score(for: title) {
            score += titleScore
        }

        // Scan the location for a match.
        if let location = self.location(),
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
