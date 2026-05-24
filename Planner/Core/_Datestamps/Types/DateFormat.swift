//
//  DateFormat.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

import Foundation

enum DateFormat {
    case countdown
    case weekday
    case dateLabel
    case dateWithoutYear
    case conciseWeekday
    case conciseMonth

    private static let ordinalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()

    func string(from datestamp: String, todaystamp: String, ordinal: Bool?)
        -> String
    {
        switch self {
        case .weekday:
            return datestamp.weekday
        case .conciseWeekday:
            return datestamp.conciseWeekday
        case .conciseMonth:
            return datestamp.conciseMonth
        case .dateWithoutYear:
            return datestamp.dateWithoutYear
        case .countdown:
            let countdown = datestamp.countdown(todaystamp: todaystamp)
            return ordinal == true
                ? countdown.lowercased()
                : countdown
        case .dateLabel:
            let dateLabel = datestamp.dateLabel(todaystamp: todaystamp)
            return ordinal == true
                ? formatOrdinalDateLabel(dateLabel)
                : dateLabel
        }
    }

    private func formatOrdinalDateLabel(
        // Must always be of the format "June 6" or "June 6, 2000"
        _ text: String
    ) -> String {
        var formatted = text

        if !formatted.contains(","),
            let dayString = formatted.split(separator: " ").last,
            let dayInt = Int(dayString),
            let ordinalDay = Self.ordinalFormatter.string(
                from: NSNumber(value: dayInt)
            ),
            let range = formatted.range(
                of: dayString,
                options: .backwards
            )
        {
            formatted.replaceSubrange(range, with: ordinalDay)
        }

        return formatted
    }
}
