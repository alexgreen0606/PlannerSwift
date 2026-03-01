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

}
