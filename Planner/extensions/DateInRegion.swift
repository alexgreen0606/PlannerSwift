//
//  DateInRegion.swift
//  Planner
//
//  Created by Alex Green on 2/13/26.
//

import SwiftDate
import SwiftUI

// Clean

extension DateInRegion {

    var datestamp: String {  // Ex: 2025-12-31
        self.toFormat("yyyy-MM-dd")
    }

    var weekday: String {  // Ex: Wednesday
        self.toFormat(
            "EEEE",
            locale: Locale.current
        )
    }

    var dynamicHeader: String {
        isThisWeek ? weekday : dateLabel
    }

    var dynamicSubheader: String {
        isThisWeek ? dateLabel : weekday
    }

    var timeWithTimezone: String? {  // EX: 3PM CST, 3:59AM GMT
        guard let timeZoneAbbreviation = region.timeZone.abbreviation() else {
            return nil
        }

        let format = date.minute == 0 ? "ha" : "h:mma"
        let timeString = self.toFormat(format)

        return "\(timeString) \(timeZoneAbbreviation)"
    }

    var countdown: String {  // Ex: Today, Tomorrow, 3 days away, 3 days ago
        let startOfToday = DateInRegion(Date(), region: .local).dateAt(
            .startOfDay
        )

        let diff =
            Calendar.current.dateComponents(
                [.day],
                from: startOfDay.date,
                to: startOfToday.date
            ).day ?? 0

        if diff == 0 {
            return "Today"

        } else if startOfToday.isBeforeDate(startOfDay, granularity: .day) {
            let absDiff = abs(diff)
            if absDiff == 1 { return "Tomorrow" }
            
            return "\(absDiff) days away"

        } else {
            if diff == 1 { return "Yesterday" }
            
            return "\(diff) days ago"
        }
    }

    var timeValue: (timeValue: String, indicator: String) {  // Ex: (12:37, PM)
        // Convert to 12-hour format.
        let hour12 = self.hour % 12 == 0 ? 12 : hour % 12
        let timeValue = String(format: "%02d:%02d", hour12, self.minute)

        // Drop off leading 0's.
        let trimmed = timeValue.drop(while: { $0 == "0" })

        // Determine AM or PM.
        let indicator = hour < 12 ? "AM" : "PM"

        return (timeValue: String(trimmed), indicator: indicator)
    }

    // MARK: - Helper Variables

    private var startOfDay: DateInRegion {
        self.dateAt(.startOfDay)
    }

    private var dateLabel: String {
        let startOfToday = DateInRegion(region: region).dateAt(.startOfDay)
        let currentYear = startOfToday.year
        return startOfDay.year == currentYear ? dateWithoutYear : dateWithYear
    }

    private var isThisWeek: Bool {
        let startOfDay = self.dateAt(.startOfDay)
        let startOfToday = DateInRegion(region: region).dateAt(.startOfDay)

        if startOfDay < startOfToday {
            return false
        }

        let daysFromToday =
            startOfDay.difference(in: .day, from: startOfToday) ?? 0
        if daysFromToday <= 6 {
            return true
        }

        return false
    }

    private var dateWithYear: String {  // Ex: May 12, 2025
        self.toFormat(
            "MMMM d, yyyy",
            locale: Locale.current
        )
    }

    private var dateWithoutYear: String {  // Ex: May 12
        self.toFormat(
            "MMMM d",
            locale: Locale.current
        )
    }

}
