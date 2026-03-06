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
    
    func belongsTo(_ plannerStartOfDay: DateInRegion) -> Bool {
        let startOfNextDay = plannerStartOfDay + 1.days
        let selfInRegion = self.convertTo(region: plannerStartOfDay.region)
        return selfInRegion >= plannerStartOfDay && selfInRegion < startOfNextDay
    }

}
