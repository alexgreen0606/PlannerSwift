//
//  dayDifference.swift
//  Planner
//
//  Created by Alex Green on 3/19/26.
//

import SwiftUI

// Clean

func dayDifference(from: String, to: String) -> Int? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)

    guard let start = formatter.date(from: from),
        let end = formatter.date(from: to)
    else {
        return nil
    }

    let seconds = end.timeIntervalSince(start)
    return Int(seconds / 86400)
}
