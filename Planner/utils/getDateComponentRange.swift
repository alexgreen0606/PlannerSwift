//
//  getDateComponentRange.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftDate
import SwiftUI

// Clean

func getDateComponentRange(
    from startDatestamp: String,
    to endDatestamp: String
) -> Set<DateComponents> {
    let calendar = Calendar.current

    var dateComponents: Set<DateComponents> = []

    guard
        var current = DateInRegion(startDatestamp, region: .local)?
            .dateAtStartOf(.day)
    else {
        return dateComponents
    }

    guard
        let end = DateInRegion(endDatestamp, region: .local)?.dateAtEndOf(
            .day
        )
    else {
        return dateComponents
    }

    while current <= end {
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: current.date
        )
        dateComponents.insert(components)
        current = current + 1.days
    }

    return dateComponents
}
