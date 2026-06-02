//
//  dateRangeIncludes.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import Foundation
import SwiftDate

// TODO: refine
func dateRangeIncludes(startTime: Date, endTime: Date, startOfDay: DateInRegion)
    -> Bool
{
    let dayStart = startOfDay.date
    let nextDayStart = (startOfDay + 1.days).date
    return startTime < nextDayStart && endTime >= dayStart
}
