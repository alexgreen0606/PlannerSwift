//
//  getChronologicalPossibleDatestamps.swift
//  Planner
//
//  Created by Alex Green on 3/1/26.
//

import Foundation
import SwiftDate

// Clean

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

// Gets all possible datestamps a date can land in.
// Example: A date could be nighttime in Los Angeles and morning the next day in Rome.
func getChronologicalPossibleDatestamps(for date: Date) -> [String] {
    return Set([
        date.in(region: earliestRegion).datestamp,
        date.in(region: latestRegion).datestamp,
    ]).sorted()
}
