//
//  Date.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

// Clean

extension Date {

    var roundedDownNearest5Minutes: Date {
        let interval: TimeInterval = 5 * 60
        let time = self.timeIntervalSince1970
        let rounded = floor(time / interval) * interval
        return Date(timeIntervalSince1970: rounded)
    }

    func belongsTo(_ plannerDay: DateInRegion) -> Bool {
        let startOfNextDay = plannerDay + 1.days
        let selfInRegion = self.convertTo(region: plannerDay.region)
        return selfInRegion >= plannerDay && selfInRegion < startOfNextDay
    }

}
