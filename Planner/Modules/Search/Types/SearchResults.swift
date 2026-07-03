//
//  SearchResults.swift
//  Planner
//
//  Created by Alex Green on 6/29/26.
//

struct SearchResults {
    let datestampMap: [String: [String]]
    let topDatestamp: String?
    let sortedYears: [String]
    let activeQuery: SearchQuery

    init(
        datestampMap: [String: [String]] = [:],
        topDatestamp: String? = nil,
        sortedYears: [String] = [],
        activeQuery: SearchQuery
    ) {
        self.datestampMap = datestampMap
        self.topDatestamp = topDatestamp
        self.sortedYears = sortedYears
        self.activeQuery = activeQuery
    }
}
