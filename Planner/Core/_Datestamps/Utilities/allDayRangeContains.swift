//
//  allDayRangeContains.swift
//  Planner
//
//  Created by Alex Green on 8/3/26.
//

import Foundation
import SwiftDate

func allDayRangeContains(
    datestamp: String,
    startDate: Date,
    endDate: Date,
    timeZoneId: String?
) -> Bool {
    guard
        let timeZone = TimeZone(
            identifier: timeZoneId ?? TimeZone.current.identifier
        )
    else {
        return false
    }

    let region = Region(
        calendar: Calendars.gregorian,
        zone: timeZone,
        locale: Locale.current
    )

    var current =
        startDate
        .in(region: region)
        .dateAtStartOf(.day)

    let end =
        endDate
        .in(region: region)
        .dateAtStartOf(.day)

    while current <= end {
        if current.datestamp == datestamp {
            return true
        }

        current = current + 1.days
    }

    return false
}
