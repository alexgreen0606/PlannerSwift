//
//  proximityFormat.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftDate
import SwiftUI

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

    func matches(_ date: DateInRegion) -> Bool {
        switch self {
        case .withinADay:
            return date.isWithinADay
        case .next7Days:
            return date.isNext7Days
        case .fallback:
            return true
        }
    }
}

enum DateFormat {
    case countdown
    case weekday
    case dateLabel

    func string(from date: DateInRegion, ordinal: Bool?) -> String {
        switch self {
        case .weekday:
            return date.weekday
        case .countdown:
            return ordinal == true
                ? date.countdown.lowercased() : date.countdown
        case .dateLabel:
            return ordinal == true ? formatOrdinalDateString(date.dateLabel) : date.dateLabel
        }
    }
}

extension DateInRegion {

    // Formats date strings based on their proximity to today.
    func proximityFormat(
        using rules: [ProximityRule]
    ) -> String {
        for rule in rules {
            if rule.proximity.matches(self) {
                return rule.format.string(from: self, ordinal: rule.ordinal)
            }
        }
        return ""
    }

}
