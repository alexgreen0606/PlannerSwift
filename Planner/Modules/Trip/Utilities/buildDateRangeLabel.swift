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
    if firstDatestamp == lastDatestamp {
        // Single-day range.
        return firstDatestamp.dateLabel(todaystamp: todaystamp)
    }

    let currentYear = referenceYear ?? todaystamp.year
    let sameYear = firstDatestamp.year == lastDatestamp.year
    let sameMonth = sameYear && firstDatestamp.monthDigit == lastDatestamp.monthDigit

    let startIncludeMonth = true
    let startIncludeYear = !sameYear

    let endIncludeMonth = !sameMonth
    let endIncludeYear = lastDatestamp.year != currentYear

    let start = format(
        firstDatestamp,
        includeMonth: startIncludeMonth,
        includeYear: startIncludeYear,
        todaystamp: todaystamp
    )
    let end = format(
        lastDatestamp,
        includeMonth: endIncludeMonth,
        includeYear: endIncludeYear,
        todaystamp: todaystamp
    )

    return "\(start) - \(end)"
}

// MARK: - Helper Functions

private func format(
    _ datestamp: String,
    includeMonth: Bool,
    includeYear: Bool,
    todaystamp: String
) -> String {
    let parts = datestamp.split(separator: "-")
    guard parts.count == 3 else { return datestamp.dateLabel(todaystamp: todaystamp) }

    let year = String(parts[0])
    let month = Int(parts[1]) ?? 0
    let day = Int(parts[2]) ?? 0

    let monthNames = [
        "", "January", "February", "March",
        "April", "May", "June",
        "July", "August", "September",
        "October", "November", "December",
    ]

    var result = ""

    if includeMonth, month > 0, month < monthNames.count {
        result += "\(monthNames[month]) "
    }

    result += "\(day)"

    if includeYear {
        result += ", \(year)"
    }

    return result
}
