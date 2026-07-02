//
//  Trip+Search.swift
//  Planner
//
//  Created by Alex Green on 7/1/26.
//

import Foundation

extension Trip {
    static func trips(
        matching query: PlannerSearchQuery
    ) -> Predicate<Trip> {
        let todaystamp = query.todayStartOfDay.datestamp

        if query.past {
            // Trips in the past.
            return #Predicate<Trip> {
                $0.firstDatestamp < todaystamp
            }
        } else {
            // Trips in the present and future.
            return #Predicate<Trip> {
                $0.lastDatestamp >= todaystamp
            }
        }
    }

    func searchQueryScore(_ query: PlannerSearchQuery) -> Double? {
        if !query.calendarIds.isEmpty {
            // Filtering by calendar events only. Exclude.
            return nil
        }
        
        if !query.containsDatestampRange(
            startDatestamp: firstDatestamp,
            endDatestamp: lastDatestamp
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
