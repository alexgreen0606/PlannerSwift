//
//  Date.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

extension Date {
    private static let datestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    var datestamp: String { // Ex: 2025-12-31
        Self.datestampFormatter.string(from: self)
    }

    var roundedDownNearest5Minutes: Date {
        let interval: TimeInterval = 5 * 60
        let time = timeIntervalSince1970
        let rounded = floor(time / interval) * interval
        return Date(timeIntervalSince1970: rounded)
    }

    func belongsTo(_ plannerDay: DateInRegion) -> Bool {
        let startOfNextDay = plannerDay + 1.days
        let selfInRegion = convertTo(region: plannerDay.region)
        return selfInRegion >= plannerDay && selfInRegion < startOfNextDay
    }
}
