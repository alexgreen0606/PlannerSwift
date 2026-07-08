//
//  EKEvent+Search.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit

extension EKEvent {
    func searchQueryScore(
        _ query: SearchQuery,
        /// Used to determine if event's planner matches the query.
        in plannerDatestamp: String
    ) -> Double? {
        guard !query.isCalendarHidden(calendarId: calendar.calendarIdentifier)
        else {
            // Calendar is hidden. Exclude.
            return nil
        }

        guard
            query.containsDateRange(
                startDate: startDate,
                endDate: endDate
            )
        else {
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

        // Scan the planner for a match when searching calendar events.
        // This helps us pin-point calendar events in certain months or weekdays.
        if !query.calendarIds.isEmpty {
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
