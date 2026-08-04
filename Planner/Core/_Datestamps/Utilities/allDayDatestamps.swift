//
//  allDayDatestamps.swift
//  Planner
//
//  Created by Alex Green on 8/3/26.
//

import Foundation
import SwiftDate

func allDayDatestamps(
    startDate: Date,
    endDate: Date,
    timeZoneId: String?
) -> Set<String> {
    guard
        let timeZone = TimeZone(
            identifier: timeZoneId ?? TimeZone.current.identifier
        )
    else {
        return []
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

    var datestamps: Set<String> = []

    while current <= end {
        datestamps.insert(current.datestamp)
        current = current + 1.days
    }

    return datestamps
}
