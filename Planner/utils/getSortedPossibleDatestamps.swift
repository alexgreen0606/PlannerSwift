//
//  getSortedPossibleDatestamps.swift
//  Planner
//
//  Created by Alex Green on 3/1/26.
//

import Foundation
import SwiftDate

// Clean

// Gets all possible datestamps an event can land in.
// Example: An event could be nighttime in Los Angeles and morning the next day in Rome.
func getSortedPossibleDatestamps(for date: Date, ending: Date? = nil)
    -> [String]
{
    var current = date.in(region: earliestRegion).dateAtStartOf(.day)
    let end = (ending ?? date).in(region: latestRegion).dateAtEndOf(.day)

    var datestamps: Set<String> = [current.datestamp, end.datestamp]

    while current <= end {
        datestamps.insert(current.datestamp)
        current = current + 1.days
    }

    return datestamps.sorted()
}

// MARK: - Helpers

private let earliestRegion = Region(
    calendar: Calendars.gregorian,
    zone: TimeZone(secondsFromGMT: -12 * 3600)!,
    locale: Locales.english
)

private let latestRegion = Region(
    calendar: Calendars.gregorian,
    zone: TimeZone(secondsFromGMT: 14 * 3600)!,
    locale: Locales.english
)
