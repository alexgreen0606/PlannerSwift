//
//  tripDateRangeLabel.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

func tripDateRangeLabel(
    firstDatestamp: String,
    lastDatestamp: String,
    todaystamp: String,
    referenceYear customReferenceYear: String? = nil
) -> String {
    if firstDatestamp == lastDatestamp {
        // Single-day range.
        return firstDatestamp.dateLabel(todaystamp: todaystamp)
    }

    let referenceYear = customReferenceYear ?? todaystamp.year
    let sameYear = firstDatestamp.year == lastDatestamp.year
    let sameMonth = sameYear && firstDatestamp.monthDigit == lastDatestamp.monthDigit

    let includeStartMonth = true
    let includeStartYear = !sameYear

    let includeEndMonth = !sameMonth
    let includeEndYear = lastDatestamp.year != referenceYear

    let startLabel = format(
        firstDatestamp,
        includeMonth: includeStartMonth,
        includeYear: includeStartYear,
        todaystamp: todaystamp
    )
    
    let endLabel = format(
        lastDatestamp,
        includeMonth: includeEndMonth,
        includeYear: includeEndYear,
        todaystamp: todaystamp
    )

    return "\(startLabel) - \(endLabel)"
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
