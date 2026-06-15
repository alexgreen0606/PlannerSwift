//
//  Date+PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

extension Date {
    /// Note: This date can be assumed to be an event start time. Do not use this function for end times.
    func belongsToPlanner(startOfDay: DateInRegion) -> Bool {
        let startOfNextDay = startOfDay + 1.days
        let selfInRegion = convertTo(region: startOfDay.region)

        return selfInRegion >= startOfDay && selfInRegion < startOfNextDay
    }
}
