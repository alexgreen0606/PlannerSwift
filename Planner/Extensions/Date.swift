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
    // TODO: not correct for before yesterday.
    var header: String {
        let date = DateInRegion(self, region: .current)
        let today = DateInRegion(region: .current)

        // Difference in whole days
        let daysFromToday =
            date.dateAt(.startOfDay)
            .difference(in: .day, from: today.dateAt(.startOfDay)) ?? 0

        // 0...6 days in the future → weekday
        if daysFromToday >= 0 && daysFromToday <= 6 {
            return date.toFormat("EEEE", locale: Locale.current)
        }

        // Past (yesterday or earlier) → long date
        let currentYear = today.year

        if date.year == currentYear {
            return date.toFormat("MMMM d", locale: Locale.current)
        } else {
            return date.toFormat("MMMM d, yyyy", locale: Locale.current)
        }
    }

    // Shows the full date for the next week. Otherwise the day of week is shown.
    // TODO: not correct for before yesterday.
    var subHeader: String {
        let date = DateInRegion(self, region: .current)
        let today = DateInRegion(region: .current)

        let daysFromToday =
            date.dateAt(.startOfDay)
            .difference(in: .day, from: today.dateAt(.startOfDay)) ?? 0

        // 0...6 days in the future → date
        if daysFromToday >= 0 && daysFromToday <= 6 {
            let currentYear = today.year

            if date.year == currentYear {
                return date.toFormat("MMMM d", locale: Locale.current)
            } else {
                return date.toFormat("MMMM d, yyyy", locale: Locale.current)
            }
        }

        // Past (yesterday or earlier) → weekday
        return date.toFormat("EEEE", locale: Locale.current)
    }

    var datestamp: String {  // Ex: 2025-12-31
        let dateInRegion = DateInRegion(self, region: .local)
        return dateInRegion.toFormat("yyyy-MM-dd")
    }

    var timeValues:
        (
            timeValue: String, indicator: String
        )
    {
        let dateInRegion = DateInRegion(self, region: .current)

        // Format hours and minutes in 12-hour clock
        let hour = dateInRegion.hour
        let minute = dateInRegion.minute

        // Convert to 12-hour format
        let hour12 = hour % 12 == 0 ? 12 : hour % 12
        let timeValue = String(format: "%02d:%02d", hour12, minute)
        let trimmed = timeValue.drop(while: { $0 == "0" })

        // Determine AM or PM
        let indicator = hour < 12 ? "AM" : "PM"

        return (timeValue: String(trimmed), indicator: indicator)
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
