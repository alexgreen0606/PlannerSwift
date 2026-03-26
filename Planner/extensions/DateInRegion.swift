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

    var dynamicTitle: String {
        isThisWeek ? weekday : dateLabel
    }

    // Same as dynamicTitle, but includes "th", "rd", etc.
    var dynamicSentenceTitle: String {
        var formatted = self.dynamicTitle

        if !formatted.contains(",") {
            if let dayString = formatted.split(separator: " ").last,
                let day = Int(dayString)
            {

                let suffix: String
                switch day % 100 {
                case 11, 12, 13:
                    suffix = "th"
                default:
                    switch day % 10 {
                    case 1: suffix = "st"
                    case 2: suffix = "nd"
                    case 3: suffix = "rd"
                    default: suffix = "th"
                    }
                }

                formatted += suffix
            }
        }

        return formatted
    }

    var dynamicSubtitle: String {
        isThisWeek ? dateLabel : weekday
    }

    func previewTitle(type: PlannerPreviewType) -> String {
        if type == .trip {
            return ""  // This will be custom computed inside TripView.
        }

        let todaystamp = DateInRegion(Date(), region: .local).datestamp

        guard let dayDiff = dayDifference(from: datestamp, to: todaystamp)
        else {
            return dynamicTitle
        }

        if abs(dayDiff) < 2 {
            return countdown
        }

        return isThisWeek ? self.weekday : self.countdown
    }

    func previewSubtitle(type: PlannerPreviewType) -> String {
        if type == .trip {
            return self.weekday
        }

        let todaystamp = DateInRegion(Date(), region: .local).datestamp

        guard let dayDiff = dayDifference(from: datestamp, to: todaystamp)
        else {
            return dynamicTitle
        }

        if abs(dayDiff) < 2 {
            return self.weekday
        }

        return isThisWeek ? self.countdown : self.weekday
    }

    var notificationDayLabel: String {
        let todaystamp = DateInRegion(Date(), region: .local).datestamp

        guard let dayDiff = dayDifference(from: self.datestamp, to: todaystamp)
        else {
            return dynamicTitle
        }

        if abs(dayDiff) < 2 {
            return countdown.lowercased()
        }

        if dayDiff > 1 && dayDiff < 7 {
            return "last \(weekday)"
        }

        if dayDiff < -1 && dayDiff > -7 {
            return weekday
        }

        return dateLabel
    }

    var tripLabel: String {
        let todaystamp = DateInRegion(Date(), region: .local).datestamp

        guard let dayDiff = dayDifference(from: datestamp, to: todaystamp)
        else {
            return self.dynamicTitle
        }

        if abs(dayDiff) < 2 {
            return countdown
        }

        return self.dynamicTitle
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
    
    var dateLabel: String {
        let startOfToday = DateInRegion(region: region).dateAt(.startOfDay)
        let currentYear = startOfToday.year
        return startOfDay.year == currentYear ? dateWithoutYear : dateWithYear
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
