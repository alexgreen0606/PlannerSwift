//
//  PlannerSearchResults.swift
//  Planner
//
//  Created by Alex Green on 6/29/26.
//

struct PlannerSearchResults {
    let datestampMap: [String: [String]]
    let topDatestamp: String?
    let sortedYears: [String]
    let activeQuery: PlannerSearchQuery?

    init(
        datestampMap: [String: [String]] = [:],
        topDatestamp: String? = nil,
        sortedYears: [String] = [],
        activeQuery: PlannerSearchQuery? = nil
    ) {
        self.datestampMap = datestampMap
        self.topDatestamp = topDatestamp
        self.sortedYears = sortedYears
        self.activeQuery = activeQuery
    }
}
