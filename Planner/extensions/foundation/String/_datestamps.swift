//
//  datestamps.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import Foundation
import SwiftDate

// Clean

struct ProximityRule {
    let proximity: TodayProximity
    let format: DateFormat
    let ordinal: Bool

    init(proximity: TodayProximity, format: DateFormat, ordinal: Bool = false) {
        self.proximity = proximity
        self.format = format
        self.ordinal = ordinal
    }
}

enum TodayProximity {
    case withinADay
    case next7Days
    case fallback

    func matches(_ datestamp: String, todaystamp: String) -> Bool {
        switch self {
        case .withinADay:
            return datestamp.isWithinADay(todaystamp: todaystamp)
        case .next7Days:
            return datestamp.isNext7Days(todaystamp: todaystamp)
        case .fallback:
            return true
        }
    }
}

enum DateFormat {
    case countdown
    case weekday
    case dateLabel
    case dateWithoutYear
    case shortWeekday
    case shortMonth

    func string(from datestamp: String, todaystamp: String, ordinal: Bool?)
        -> String
    {
        switch self {
        case .weekday:
            return datestamp.weekday
        case .shortWeekday:
            return datestamp.shortWeekday
        case .shortMonth:
            return datestamp.shortMonth
        case .countdown:
            return ordinal == true
                ? datestamp.countdown(todaystamp: todaystamp).lowercased()
                : datestamp.countdown(todaystamp: todaystamp)
        case .dateWithoutYear:
            return datestamp.dateWithoutYear
        case .dateLabel:
            return ordinal == true
                ? formatOrdinalDateString(datestamp.dateLabel)
                : datestamp.dateLabel
        }
    }
}

extension String {

    // MARK: - Base Formatter (yyyy-MM-dd)

    private static let baseFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    // MARK: - Thread-Safe Caches

    private static var formatterCache: [String: DateFormatter] = [:]
    private static let formatterQueue = DispatchQueue(
        label: "formatter.cache.queue"
    )

    private static var dateCache: [String: Date] = [:]
    private static let dateQueue = DispatchQueue(label: "date.cache.queue")

    // MARK: - Formatter Access

    private static func formatter(for format: String) -> DateFormatter {
        formatterQueue.sync {
            if let cached = formatterCache[format] {
                return cached
            }

            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale.current

            formatterCache[format] = formatter
            return formatter
        }
    }

    // MARK: - Date Parsing

    private func toDate() -> Date? {
        Self.dateQueue.sync {
            if let cached = Self.dateCache[self] {
                return cached
            }

            guard let date = Self.baseFormatter.date(from: self) else {
                return nil
            }

            Self.dateCache[self] = date
            return date
        }
    }

    // MARK: - Formatting Helper

    private func formatted(_ format: String) -> String {
        guard let date = toDate() else { return "" }
        return Self.formatter(for: format).string(from: date)
    }

    // MARK: - Public API

    var weekday: String {  // Ex: Wednesday
        formatted("EEEE")
    }

    var shortMonth: String {  // Ex: APR, JUN
        formatted("MMM").uppercased()
    }

    var shortWeekday: String {  // Ex: MON, WED
        formatted("EEE").uppercased()
    }

    // MARK: - Countdown

    func countdown(todaystamp: String) -> String {
        let current = self

        if current == todaystamp { return "Today" }

        guard let diff = dayDifference(from: current, to: todaystamp)
        else { return "" }

        if current > todaystamp {
            let absDiff = abs(diff)
            if absDiff == 1 { return "Tomorrow" }
            return "\(absDiff) days away"
        } else {
            if diff == 1 { return "Yesterday" }
            return "\(diff) days ago"
        }
    }

    // MARK: - Date Label

    var dateLabel: String {
        guard let date = toDate() else { return "" }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let year = calendar.component(.year, from: date)

        return year == currentYear ? dateWithoutYear : dateWithYear
    }

    var dateWithoutYear: String {  // Ex: May 12
        formatted("MMMM d")
    }

    var dateWithYear: String {  // Ex: May 12, 2025
        formatted("MMMM d, yyyy")
    }

    // MARK: - Proximity Evaluators

    // True if between Today and the next 6 days.
    func isNext7Days(todaystamp: String) -> Bool {
        if self < todaystamp {
            return false
        }

        guard let diff = dayDifference(from: todaystamp, to: self)
        else { return false }

        return diff < 7
    }

    // True if Yesterday, Today, or Tomorrow.
    func isWithinADay(todaystamp: String) -> Bool {
        guard let diff = dayDifference(from: self, to: todaystamp)
        else { return false }

        return abs(diff) < 2
    }

    // MARK: - Proximity Format

    // Formats date strings based on their proximity to today.
    func proximityFormat(
        using rules: [ProximityRule],
        todaystamp: String
    ) -> String {
        for rule in rules {
            if rule.proximity.matches(self, todaystamp: todaystamp) {
                return rule.format.string(
                    from: self,
                    todaystamp: todaystamp,
                    ordinal: rule.ordinal
                )
            }
        }
        return ""
    }

    // MARK: - TODO

    // Expects YYYY-MM-DD format.
    var calendarSymbolName: String {
        let dd = self.suffix(2)

        guard let day = Int(dd), (1...31).contains(day) else {
            return "note"
        }

        return "\(day).calendar"
    }

    // Expects YYYY-MM-DD format.
    func startOfDay(in region: Region) -> DateInRegion? {
        guard
            let result = self.toDate("yyyy-MM-dd", region: region)?
                .dateAtStartOf(.day)
        else {
            assertionFailure(
                "ERROR String: Could not create DateInRegion from \(self)"
            )
            return nil
        }
        return result
    }
    
    // Expects YYYY-MM-DD format.
    var dateComponents: DateComponents? {
        let parts = self.split(separator: "-")
        guard parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return nil
        }

        return DateComponents(year: year, month: month, day: day)
    }

}
