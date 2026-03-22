//
//  getSortedDatestampRange.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import Foundation
import SwiftDate

func getSortedDatestampRange(
    from startDatestamp: String,
    to endDatestamp: String
) -> [String] {
    var datestamps: Set<String> = [startDatestamp, endDatestamp]

    guard
        var current = DateInRegion(startDatestamp, region: .local)?
            .dateAtStartOf(.day)
    else {
        return datestamps.sorted()
    }

    guard
        let end = DateInRegion(endDatestamp, region: .local)?.dateAtEndOf(
            .day
        )
    else {
        return datestamps.sorted()
    }

    while current <= end {
        datestamps.insert(current.datestamp)
        current = current + 1.days
    }

    return datestamps.sorted()
}
