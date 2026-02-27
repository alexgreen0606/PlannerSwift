//
//  Date.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

extension Date {
    
    func belongsTo(_ day: DateInRegion) -> Bool {
        let startOfDay = day.dateAt(.startOfDay)
        let startOfNextDay = startOfDay + 1.days

        let convertedSelf = self.convertTo(region: day.region)

        return convertedSelf >= startOfDay && convertedSelf < startOfNextDay
    }

    // TODO: is this needed?
    func shiftDate(to startOfDay: DateInRegion, from sourceStartOfDay: DateInRegion) -> Date {

        // TODO: Preserve the time of day.
        // Example, if date is 3PM in EST, and is now transfering to GST, the time should now be 3PM in GST

        return Date()
        
//        original.dateBySet([
//            .year: newDate.year,
//            .month: newDate.month,
//            .day: newDate.day,
//        ])?.date
    }

}
