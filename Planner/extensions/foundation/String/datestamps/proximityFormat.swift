//
//  proximityFormat.swift
//  Planner
//
//  Created by Alex Green on 4/9/26.
//

import Foundation
import SwiftDate

// Clean

struct ProximityRule {
    let proximity: TodayProximity
    let format: DateFormat
    let ordinal: Bool

    init(proximity: TodayProximity, format: DateFormat, ordinal: Bool = false) {
        self.proximity = proximity
        self.format = format
        self.ordinal = ordinal
    }
}

enum TodayProximity {
    case withinADay
    case next7Days
    case fallback

    func matches(_ datestamp: String, todaystamp: String) -> Bool {
        switch self {
        case .withinADay:
            return datestamp.isWithinADay(todaystamp: todaystamp)
        case .next7Days:
            return datestamp.isNext7Days(todaystamp: todaystamp)
        case .fallback:
            return true
        }
    }
}

enum DateFormat {
    case countdown
    case weekday
    case dateLabel
    case dateWithoutYear
    case shortWeekday
    case shortMonth

    func string(from datestamp: String, todaystamp: String, ordinal: Bool?)
        -> String
    {
        switch self {
        case .weekday:
            return datestamp.weekday
        case .shortWeekday:
            return datestamp.shortWeekday
        case .shortMonth:
            return datestamp.shortMonth
        case .countdown:
            return ordinal == true
                ? datestamp.countdown(todaystamp: todaystamp).lowercased()
                : datestamp.countdown(todaystamp: todaystamp)
        case .dateWithoutYear:
            return datestamp.dateWithoutYear
        case .dateLabel:
            return ordinal == true
                ? formatOrdinalDateString(datestamp.dateLabel)
                : datestamp.dateLabel
        }
    }
}

extension String {

    // Formats date strings based on their proximity to today.
    func proximityFormat(
        using rules: [ProximityRule],
        todaystamp: String
    ) -> String {
        for rule in rules {
            if rule.proximity.matches(self, todaystamp: todaystamp) {
                return rule.format.string(
                    from: self,
                    todaystamp: todaystamp,
                    ordinal: rule.ordinal
                )
            }
        }
        return ""
    }

    // MARK: - Proximity Evaluators

    // True if between Today and the next 6 days.
    func isNext7Days(todaystamp: String) -> Bool {
        if self < todaystamp {
            return false
        }

        guard let diff = dayDifference(from: todaystamp, to: self)
        else { return false }

        return diff < 7
    }

    // True if Yesterday, Today, or Tomorrow.
    func isWithinADay(todaystamp: String) -> Bool {
        guard let diff = dayDifference(from: self, to: todaystamp)
        else { return false }

        return abs(diff) < 2
    }

}
