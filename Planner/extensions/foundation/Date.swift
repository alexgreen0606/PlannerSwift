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
    
    func belongsTo(_ plannerDay: DateInRegion) -> Bool {
        let startOfNextDay = plannerDay + 1.days
        let selfInRegion = self.convertTo(region: plannerDay.region)
        return selfInRegion >= plannerDay && selfInRegion < startOfNextDay
    }

}
