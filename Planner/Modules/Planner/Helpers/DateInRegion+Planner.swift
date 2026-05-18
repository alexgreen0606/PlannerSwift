//
//  DateInRegion+Planner.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftDate
import SwiftUI

extension DateInRegion {
    var datestamp: String { // Ex: 2000-06-06
        toFormat("yyyy-MM-dd")
    }

    var timeWithTimezone: String? { // EX: 3PM CST, 3:59AM GMT
        guard let timeZoneAbbreviation = region.timeZone.abbreviation() else {
            return nil
        }

        let format = date.minute == 0 ? "ha" : "h:mma"
        let timeString = toFormat(format)

        return "\(timeString) \(timeZoneAbbreviation)"
    }
}
