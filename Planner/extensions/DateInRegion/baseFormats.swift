//
//  baseFormats.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
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

    var shortMonth: String {  // Ex: APR, JUN
        self.toFormat(
            "MMM",
            locale: Locale.current
        ).uppercased()
    }

    var shortWeekday: String {  // Ex: MON, WED
        self.toFormat(
            "EEE",
            locale: Locale.current
        ).uppercased()
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
        let todaystamp = DateInRegion(Date(), region: .local).datestamp
        let datestamp = self.datestamp

        if self.datestamp == todaystamp { return "Today" }

        guard let dayDiff = dayDifference(from: datestamp, to: todaystamp)
        else {
            return ""
        }

        if datestamp > todaystamp {
            let absDiff = abs(dayDiff)
            if absDiff == 1 { return "Tomorrow" }

            return "\(absDiff) days away"

        } else {
            if dayDiff == 1 { return "Yesterday" }

            return "\(dayDiff) days ago"
        }
    }

    // MARK: Date Label

    var dateLabel: String {
        let startOfToday = DateInRegion(region: region).dateAt(.startOfDay)
        let currentYear = startOfToday.year
        return self.year == currentYear ? dateWithoutYear : dateWithYear
    }

    var dateWithoutYear: String {  // Ex: May 12
        self.toFormat(
            "MMMM d",
            locale: Locale.current
        )
    }

    private var dateWithYear: String {  // Ex: May 12, 2025
        self.toFormat(
            "MMMM d, yyyy",
            locale: Locale.current
        )
    }

}
