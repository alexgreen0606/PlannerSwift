//
//  Planner+Search.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

extension Planner {
    func searchQueryScore(_ query: PlannerSearchQuery?) ->
        /// Note: nil means the event doesn't match the query.
        Double?
    {
        guard let query else {
            // Include. No query set.
            return 1.0
        }

        if !query.containsDatestamp(datestamp) {
            // Exclude. Doesn't match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include. No search text.
            return 1.0
        }

        if let location = location,
           let locationScore = query.score(for: location.name)
        {
            // Include. Location matches the search text.
            return locationScore
        }

        return nil
    }
}
