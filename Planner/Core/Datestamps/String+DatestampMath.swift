//
//  String+DatestampMath.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import Foundation
import SwiftDate

extension String {
    func daysUntil(_ other: String) -> Int? {
        guard
            let start = date,
            let end = other.date
        else { return nil }

        return Calendar.current.dateComponents([.day], from: start, to: end).day
    }

    func countdown(todaystamp: String) -> String {
        if self == todaystamp { return "Today" }

        guard let diff = daysUntil(todaystamp)
        else { return "" }

        if self > todaystamp {
            let absDiff = abs(diff)
            if absDiff == 1 { return "Tomorrow" }
            return "\(absDiff) days away"
        } else {
            if diff == 1 { return "Yesterday" }
            return "\(diff) days ago"
        }
    }

    /// True if between Today and the next 6 days.
    func isNext7Days(todaystamp: String) -> Bool {
        if self < todaystamp {
            return false
        }

        guard let diff = todaystamp.daysUntil(self)
        else { return false }

        return diff < 7
    }

    /// True if Yesterday, Today, or Tomorrow.
    func isWithinADay(todaystamp: String) -> Bool {
        guard let diff = daysUntil(todaystamp)
        else { return false }

        return abs(diff) < 2
    }
}
