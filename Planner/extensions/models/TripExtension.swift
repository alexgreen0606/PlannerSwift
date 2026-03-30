//
//  TripExtension.swift
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

    var dateRangeLabel: String? {
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
            referenceYear: firstDay.year
        )
    }

    func plannerTransitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }

    func searchQueryScore(_ query: PlannerSearchQuery?) -> Double? {
        guard let query else {
            // Include when no query is set.
            return 1.0
        }

        if query.filterPast, let firstDatestamp = self.firstDatestamp,
            firstDatestamp >= query.todayStartOfDay.datestamp
        {
            // Exclude if it doesnt match the time range.
            return nil
        }

        if !query.filterPast, let lastDatestamp = self.lastDatestamp,
            lastDatestamp < query.todayStartOfDay.datestamp
        {
            // Exclude if it doesnt match the time range.
            return nil
        }

        if query.text.isEmpty {
            // Include if there is no search text.
            return 1.0
        }

        var score: Double = 0.0

        if let location = self.location,
            let results = query.fuse.search(query.text, in: location.name),
            results.score <= FuseConstants.fuzzyThreshold
        {
            // Include if the location matches the search text.
            score = 1.0 - results.score
        }

        if let results = query.fuse.search(query.text, in: self.title),
            results.score <= FuseConstants.fuzzyThreshold
        {
            // Include if the title matches the search text.
            score += (1.0 - results.score)
        }

        if score != 0.0 {
            return score
        }

        return nil
    }

}
