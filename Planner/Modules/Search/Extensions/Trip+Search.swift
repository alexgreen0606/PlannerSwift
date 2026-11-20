//
//  Trip+Search.swift
//  Planner
//
//  Created by Alex Green on 7/1/26.
//

import Foundation

extension Trip {
    static func searchableTrips(
        within bounds: PlannerBounds
    ) -> Predicate<Trip> {
        let minDatestamp = bounds.minStartOfDay.datestamp
        let maxDatestamp = bounds.maxStartOfDay.datestamp

        return #Predicate<Trip> {
            $0.firstDatestamp <= maxDatestamp
                && $0.lastDatestamp >= minDatestamp
        }
    }

    func searchQueryScore(_ query: PlannerSearchQuery) -> Double? {
        guard query.calendarIds.isEmpty else {
            // Filtering by calendar events only. Exclude.
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
        if let location,
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
