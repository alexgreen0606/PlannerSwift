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
        case .countdown:
            return ordinal == true
                ? datestamp.countdown(todaystamp: todaystamp).lowercased()
                : datestamp.countdown(todaystamp: todaystamp)
        case .dateWithoutYear:
            return datestamp.dateWithoutYear
        case .dateLabel:
            return ordinal == true
                ? formatOrdinalDateString(
                    datestamp.dateLabel(todaystamp: todaystamp)
                )
                : datestamp.dateLabel(todaystamp: todaystamp)
        }
    }
    
    private func formatOrdinalDateString(
        // Must always be of the format "June 6" or "June 6, 2000"
        _ text: String
    ) -> String {
        var formatted = text

        if !formatted.contains(",") {
            if let dayString = formatted.split(separator: " ").last,
                let dayInt = Int(dayString)
            {
                let formatter = NumberFormatter()
                formatter.numberStyle = .ordinal

                if let ordinalDay = formatter.string(from: NSNumber(value: dayInt)),
                    let range = formatted.range(of: dayString, options: .backwards)
                {
                    formatted.replaceSubrange(range, with: ordinalDay)
                }
            }
        }

        return formatted
    }
}
