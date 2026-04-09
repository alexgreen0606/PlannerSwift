//
//  buildDateRangeLabel.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

// Clean

func buildDateRangeLabel(
    firstDatestamp: String,
    lastDatestamp: String,
    todaystamp: String,
    referenceYear: String? = nil
)
    -> String
{

    // Single-day range.
    if firstDatestamp == lastDatestamp {
        return firstDatestamp.proximityFormat(
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

    let currentYear = referenceYear ?? todaystamp.year
    let sameYear = firstDatestamp.year == lastDatestamp.year
    let sameMonth = sameYear && firstDatestamp.month == lastDatestamp.month

    let startIncludeMonth = true
    let startIncludeYear = firstDatestamp.year != currentYear && !sameYear

    let endIncludeMonth = !sameMonth
    let endIncludeYear = lastDatestamp.year != currentYear

    let start = format(
        firstDatestamp,
        includeMonth: startIncludeMonth,
        includeYear: startIncludeYear
    )
    let end = format(
        lastDatestamp,
        includeMonth: endIncludeMonth,
        includeYear: endIncludeYear
    )

    return "\(start) - \(end)"
}

private func format(
    _ date: String,
    includeMonth: Bool,
    includeYear: Bool
) -> String {

    let parts = date.split(separator: "-")
    guard parts.count == 3 else { return date }

    let year = String(parts[0])
    let month = Int(parts[1]) ?? 0
    let day = String(parts[2])

    let monthNames = [
        "", "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December",
    ]

    var result = ""

    if includeMonth, month > 0, month < monthNames.count {
        result += "\(monthNames[month]) "
    }

    result += day

    if includeYear {
        result += ", \(year)"
    }

    return result
}
