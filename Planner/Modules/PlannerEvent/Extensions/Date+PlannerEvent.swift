//
//  Date+PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

extension Date {
    var roundedDownNearest5Minutes: Date {
        let interval: TimeInterval = 5 * 60
        let rounded = floor(timeIntervalSince1970 / interval) * interval
        return Date(timeIntervalSince1970: rounded)
    }

    func belongsTo(_ startOfDay: DateInRegion) -> Bool {
        let startOfNextDay = startOfDay + 1.days
        let selfInRegion = convertTo(region: startOfDay.region)
        return selfInRegion >= startOfDay && selfInRegion < startOfNextDay
    }
}
