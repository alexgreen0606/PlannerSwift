//
//  DateInRegion+PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import SwiftDate
import SwiftUI

extension DateInRegion {
    var timeWithTimezone: String? { // EX: 3PM CST, 3:59AM GMT
        guard let timeZoneAbbreviation = region.timeZone.abbreviation() else {
            return nil
        }

        let format = date.minute == 0 ? "ha" : "h:mma"
        let timeString = toFormat(format)

        return "\(timeString) \(timeZoneAbbreviation)"
    }
}
