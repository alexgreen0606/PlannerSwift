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
}
