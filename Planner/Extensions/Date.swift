//
//  Date.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

extension Date {
    var dayName: String {  // Ex: Wednesday
        DateInRegion(self, region: .current).toFormat(
            "EEEE",
            locale: Locale.current
        )
    }

    var longDate: String {  // Ex: January 12, 2025
        DateInRegion(self, region: .current).toFormat(
            "MMMM d, yyyy",
            locale: Locale.current
        )
    }

    var datestamp: String {  // Ex: 2025-12-31
        let dateInRegion = DateInRegion(self, region: .local)
        return dateInRegion.toFormat("yyyy-MM-dd")
    }

    var daysUntil: String? {  // Ex: Today, Tomorrow, 3 days away, 3 days ago
        let region = Region.local

        let target = DateInRegion(self, region: region).dateAt(.startOfDay)
        let today = DateInRegion(Date(), region: region).dateAt(.startOfDay)

        guard let diff = today.difference(in: .day, from: target) else {
            return ""
        }

        if diff == 0 {
            return "Today"
        } else if today.isBeforeDate(target, granularity: .day) {
            if diff == 1 {
                return "Tomorrow"
            }
            return "\(diff) days away"
        } else {
            if diff == 1 {
                return "Yesterday"
            }
            return "\(diff) days ago"
        }
    }
}
