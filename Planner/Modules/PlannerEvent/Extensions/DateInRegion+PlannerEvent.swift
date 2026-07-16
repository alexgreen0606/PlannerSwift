//
//  DateInRegion+PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import SwiftDate
import SwiftUI

extension DateInRegion {
    /// Example: 3PM, 3:59AM
    var timeString: String? {
        let format = date.minute == 0 ? "ha" : "h:mma"
        let timeString = toFormat(format)
        
        return "\(timeString.lowercased())"
    }
}
