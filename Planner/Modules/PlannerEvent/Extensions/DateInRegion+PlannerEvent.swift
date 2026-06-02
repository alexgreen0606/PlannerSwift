//
//  DateInRegion+PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import SwiftDate
import SwiftUI

extension DateInRegion {
    /// Example: 3PM CST, 3:59AM GMT
    var timeWithTimezone: String? {
        guard let timeZoneAbbreviation = region.timeZone.abbreviation() else {
            return nil
        }

        let format = date.minute == 0 ? "ha" : "h:mma"
        let timeString = toFormat(format)

        return "\(timeString) \(timeZoneAbbreviation)"
    }
}
