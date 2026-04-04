//
//  buildDateRangeLabel.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftDate

// Clean

func buildDateRangeLabel(firstDay: DateInRegion, lastDay: DateInRegion, todaystamp: String, referenceYear: Int? = nil)
    -> String?
{

    // Single-day range.
    if firstDay.datestamp == lastDay.datestamp {
        // TODO: remove DateInRegion here entirely.
        return firstDay.datestamp.proximityFormat(
            using: [
                ProximityRule(
                    proximity: .withinADay,
                    format: .countdown
                ),
                ProximityRule(proximity: .next7Days, format: .weekday),
                ProximityRule(proximity: .fallback, format: .dateLabel),
            ],
            todaystamp: todaystamp
        )
    }

    let currentYear = referenceYear ?? DateInRegion(region: .local).year
    let sameYear = firstDay.year == lastDay.year
    let sameMonth = sameYear && firstDay.month == lastDay.month

    let startIncludeMonth = true
    let startIncludeYear = firstDay.year != currentYear && !sameYear

    let endIncludeMonth = !sameMonth
    let endIncludeYear = lastDay.year != currentYear

    let start = format(
        firstDay,
        includeMonth: startIncludeMonth,
        includeYear: startIncludeYear
    )
    let end = format(
        lastDay,
        includeMonth: endIncludeMonth,
        includeYear: endIncludeYear
    )

    return "\(start) - \(end)"
}

private func format(_ date: DateInRegion, includeMonth: Bool, includeYear: Bool)
    -> String
{
    var format = ""

    if includeMonth {
        format += "MMMM "
    }

    format += "d"

    if includeYear {
        format += ", yyyy"
    }

    return date.toFormat(format)
}
