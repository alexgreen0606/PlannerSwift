//
//  DateInRegion+TimeRange.swift
//  Planner
//
//  Created by Alex Green on 6/8/26.
//

import Foundation
import SwiftDate

extension DateInRegion {
    func includes(startTime: Date, endTime: Date?)
        -> Bool
    {
        let dayStart = date
        let nextDayStart = (self + 1.days).date
        
        guard let endTime else {
            return startTime >= dayStart && startTime < nextDayStart
        }
        
        return startTime < nextDayStart && endTime > dayStart
    }
}
