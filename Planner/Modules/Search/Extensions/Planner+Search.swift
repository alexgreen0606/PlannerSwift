//
//  Planner+Search.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import Foundation

extension Planner {
    static func planners(
        matching query: PlannerSearchQuery
    ) -> Predicate<Planner> {
        let todaystamp = query.todayStartOfDay.datestamp

        if query.past {
            // Planners in the past that contain a location.
            return #Predicate<Planner> {
                $0.datestamp < todaystamp && $0.location != nil
            }
        } else {
            // Planners in the present or future that contain a location.
            return #Predicate<Planner> {
                $0.datestamp >= todaystamp && $0.location != nil
            }
        }
    }
    
    func searchQueryScore(_ query: PlannerSearchQuery) -> Double? {
        if !query.calendarIds.isEmpty {
            // Filtering by calendar events only. Exclude.
            return nil
        }
        
        guard let location else {
            // Doesn't have a custom location. Exclude.
            return nil
        }
        
        if !query.containsDatestamp(datestamp) {
            // Doesn't match the time range. Exclude.
            return nil
        }

        if query.text.isEmpty {
            // No search text. Complete match!
            return 1.0
        }

        // Scan the location for a match.
        if let locationScore = query.score(for: location.name) {
            return locationScore
        }

        return nil
    }
}
