//
//  Planner+Search.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import Foundation

extension Planner {
    static func planners(
        matching query: SearchQuery
    ) -> Predicate<Planner> {
        let todaystamp = query.todayStartOfDay.datestamp

        if query.past {
            // Planners in the past that contain a location.
            return #Predicate<Planner> {
                $0.location != nil && $0.datestamp < todaystamp
            }
        } else {
            // Planners in the present or future that contain a location.
            return #Predicate<Planner> {
                $0.location != nil && $0.datestamp >= todaystamp
            }
        }
    }

    func searchQueryScore(_ query: SearchQuery) -> Double? {
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

        guard query.containsDatestamp(datestamp) else {
            // Doesn't match the time range. Exclude.
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
