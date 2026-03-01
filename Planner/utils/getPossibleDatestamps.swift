//
//  getPossibleDatestamps.swift
//  Planner
//
//  Created by Alex Green on 3/1/26.
//

import Foundation
import SwiftDate

func getChronologicalPossibleDatestamps(for date: Date) -> Set<String> {
    guard
        let earliestZone = TimeZone(secondsFromGMT: -12 * 3600),
        let latestZone = TimeZone(secondsFromGMT: 14 * 3600)
    else {
        return []
    }

    let earliestRegion = Region(
        calendar: Calendars.gregorian,
        zone: earliestZone,
        locale: Locales.english
    )

    let latestRegion = Region(
        calendar: Calendars.gregorian,
        zone: latestZone,
        locale: Locales.english
    )

    let earliestDate = date.in(region: earliestRegion)
    let latestDate = date.in(region: latestRegion)
    let earliestStamp = earliestDate.datestamp
    let latestStamp = latestDate.datestamp

    return [earliestStamp, latestStamp]
}
