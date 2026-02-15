//
//  DateInRegion.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import SwiftDate
import SwiftUI

extension DateInRegion {

    // Shows day of week for the next week. Otherwise the full date is shown.
    var dynamicHeader: String {
        let date = self.dateAt(.startOfDay)
        let today = DateInRegion(region: region).dateAt(.startOfDay)

        if date < today {
            // Past date
            let currentYear = today.year
            return date.year == currentYear ? shortDate : longDate
        }

        let daysFromToday = date.difference(in: .day, from: today) ?? 0

        if daysFromToday <= 6 {
            // Within next week
            return weekday
        }

        // Future beyond a week
        let currentYear = today.year
        return date.year == currentYear ? shortDate : longDate
    }

    // Shows the full date for the next week. Otherwise the day of week is shown.
    var dynamicSubheader: String {
        let date = self.dateAt(.startOfDay)
        let today = DateInRegion(region: region).dateAt(.startOfDay)

        if date < today {
            // Past date
            return weekday
        }

        let daysFromToday = date.difference(in: .day, from: today) ?? 0

        if daysFromToday <= 6 {
            // Within next week
            let currentYear = today.year
            return date.year == currentYear ? shortDate : longDate
        }

        // Future beyond a week
        return weekday
    }

    var countdown: String? {  // Ex: Today, Tomorrow, 3 days away, 3 days ago
        let target = self.dateAt(.startOfDay)
        let today = DateInRegion(Date(), region: .local).dateAt(.startOfDay)

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

    var weekday: String {  // Ex: Wednesday
        self.toFormat(
            "EEEE",
            locale: Locale.current
        )
    }

    var datestamp: String {  // Ex: 2025-12-31
        self.toFormat("yyyy-MM-dd")
    }
    
    var timeValues: (
        timeValue: String, indicator: String, detail: String?
    ) {  // Ex: 12:37, PM, END

        // Convert to 12-hour format
        let hour12 = self.hour % 12 == 0 ? 12 : hour % 12
        let timeValue = String(format: "%02d:%02d", hour12, self.minute)
        let trimmed = timeValue.drop(while: { $0 == "0" })

        // Determine AM or PM
        let indicator = hour < 12 ? "AM" : "PM"

        return (timeValue: String(trimmed), indicator: indicator, detail: nil)
    }

    private var longDate: String {  // Ex: May 12, 2025
        self.toFormat(
            "MMMM d, yyyy",
            locale: Locale.current
        )
    }

    private var shortDate: String {  // Ex: May 12
        self.toFormat(
            "MMMM d",
            locale: Locale.current
        )
    }
    
}
