//
//  _Trip.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import Foundation
import Fuse
import SwiftDate

// Clean

extension Trip {

    var sortedPlanners: [Planner] {
        self.planners.sorted { $0.datestamp < $1.datestamp }
    }

    var firstDatestamp: String? {
        sortedPlanners.first?.datestamp
    }

    var lastDatestamp: String? {
        sortedPlanners.last?.datestamp
    }

    var dateComponents: Set<DateComponents> {
        Set(
            self.planners.compactMap { $0.datestamp.dateComponents }
        )
    }

    func dateRangeLabel(todaystamp: String) -> String? {
        guard let firstDatestamp,
            let lastDatestamp,
            let firstDay = DateInRegion(firstDatestamp, region: .local),
            let lastDay = DateInRegion(lastDatestamp, region: .local)
        else {
            return nil
        }

        return buildDateRangeLabel(
            firstDay: firstDay,
            lastDay: lastDay,
            todaystamp: todaystamp,
            referenceYear: firstDay.year
        )
    }

    func transitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }

    // MARK: - Search Helper

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double?  // nil means the event doesn't match the query
    {
        guard let query else {
            // Include. No query set.
            return 1.0
        }

        guard let firstDatestamp, let lastDatestamp else {
            return nil
        }

        if !query.containsDatestampRange(
            startDatestamp: firstDatestamp,
            endDatestamp: lastDatestamp
        ) {
            // Exclude. Doesn't match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include. No search text.
            return 1.0
        }

        var score = 0.0

        if let titleScore = query.score(for: self.title) {
            // Include. Title matches the search text.
            score += titleScore
        }

        if let location = self.location,
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
