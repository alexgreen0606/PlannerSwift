//
//  Date.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftDate
import SwiftUI

extension Date {
    // Shows day of week for the next week. Otherwise the full date is shown.
    var dynamicHeader: String {
        let date = DateInRegion(self, region: .local).dateAt(.startOfDay)
        let today = DateInRegion(region: .local).dateAt(.startOfDay)

        if date < today {
            // Past date.
            let currentYear = today.year
            return date.year == currentYear ? shortDate : longDate
        }

        let daysFromToday =
            date
            .difference(in: .day, from: today) ?? 0
        if daysFromToday <= 6 {
            // Within a week.
            return weekday
        }

        // Future date.
        let currentYear = today.year
        return date.year == currentYear ? shortDate : longDate
    }

    // Shows the full date for the next week. Otherwise the day of week is shown.
    var dynamicSubheader: String {
        let date = DateInRegion(self, region: .local).dateAt(.startOfDay)
        let today = DateInRegion(region: .local).dateAt(.startOfDay)

        if date < today {
            // Past date.
            return weekday
        }

        let daysFromToday =
            date
            .difference(in: .day, from: today) ?? 0
        if daysFromToday <= 6 {
            // Within a week
            let currentYear = today.year
            return date.year == currentYear ? shortDate : longDate
        }

        // Future date.
        return weekday
    }

    var weekday: String {  // Ex: Wednesday
        DateInRegion(self, region: .local).toFormat(
            "EEEE",
            locale: Locale.current
        )
    }

    var datestamp: String {  // Ex: 2025-12-31
        DateInRegion(self, region: .local).toFormat("yyyy-MM-dd")
    }

    func timeValues(for datestamp: String) -> (
        timeValue: String, indicator: String, detail: String?
    ) {  // Ex: 12:37, PM, END
        let dateInRegion = DateInRegion(self, region: .local)

        // Format hours and minutes in 12-hour clock
        let hour = dateInRegion.hour
        let minute = dateInRegion.minute

        // Convert to 12-hour format
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let timeValue = String(format: "%02d:%02d", hour12, minute)
        let trimmed = timeValue.drop(while: { $0 == "0" })

        // Determine AM or PM
        let indicator = hour < 12 ? "AM" : "PM"

        return (timeValue: String(trimmed), indicator: indicator, detail: nil)
    }

    var countdown: String? {  // Ex: Today, Tomorrow, 3 days away, 3 days ago
        let target = DateInRegion(self, region: .local).dateAt(.startOfDay)
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

    private var longDate: String {  // Ex: May 12, 2025
        DateInRegion(self, region: .local).toFormat(
            "MMMM d, yyyy",
            locale: Locale.current
        )
    }

    private var shortDate: String {  // Ex: May 12
        DateInRegion(self, region: .local).toFormat(
            "MMMM d",
            locale: Locale.current
        )
    }
}
