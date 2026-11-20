//
//  Planner+Search.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import Foundation

extension Planner {
    static func searchablePlanners(
        within bounds: PlannerBounds
    ) -> Predicate<Planner> {
        let minDatestamp = bounds.minStartOfDay.datestamp
        let maxDatestamp = bounds.maxStartOfDay.datestamp

        // Planners that contain a location and land within available bounds.
        return #Predicate<Planner> {
            $0.location != nil
                && $0.datestamp >= minDatestamp
                && $0.datestamp <= maxDatestamp

        }
    }

    func searchQueryScore(_ query: PlannerSearchQuery) -> Double? {
        guard query.calendarIds.isEmpty else {
            // Filtering by calendar events only. Exclude.
            return nil
        }

        guard !query.text.isEmpty else {
            // No search text. Exclude.
            return nil
        }

        guard let location else {
            // Doesn't have a custom location. Exclude.
            return nil
        }

        // Scan the location for a match.
        if let locationScore = query.score(for: location.name) {
            return locationScore
        }

        // Location doesn't match the search query. Exclude.
        return nil
    }
}
