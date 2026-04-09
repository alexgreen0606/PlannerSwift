//
//  dateFormats.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import Foundation
import SwiftDate

// Clean

extension String {

    // Ex: "2026"
    var year: String {
        let components = self.split(separator: "-")
        guard components.count >= 1 else { return "" }
        return String(components[0])
    }

    // Ex: "12"
    var month: String {
        let components = self.split(separator: "-")
        guard components.count >= 2 else { return "" }
        return String(components[1])
    }

    // Ex: "Wednesday"
    var weekday: String {
        formatted("EEEE")
    }

    // Ex: "APR", "JUN"
    var shortMonth: String {
        formatted("MMM").uppercased()
    }

    // Ex: "MON", "WED"
    var shortWeekday: String {
        formatted("EEE").uppercased()
    }

    // MARK: Countdown

    // EX: "Today", "Tomorrow", "3 days away", "3 days ago"
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

    // MARK: Date Label

    // EX: "May 12", "May 12, 2032"
    var dateLabel: String {
        guard let date = toDate() else { return "" }

        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let year = calendar.component(.year, from: date)

        return year == currentYear ? dateWithoutYear : dateWithYear
    }

    // Ex: "May 12"
    var dateWithoutYear: String {
        formatted("MMMM d")
    }

    // Ex: "May 12, 2032"
    var dateWithYear: String {
        formatted("MMMM d, yyyy")
    }

    // MARK: - Helpers

    // MARK: Caches

    private static var formatterCache: [String: DateFormatter] = [:]
    private static let formatterQueue = DispatchQueue(
        label: "formatter.cache.queue"
    )

    private static var dateCache: [String: Date] = [:]
    private static let dateQueue = DispatchQueue(label: "date.cache.queue")

    // MARK: Formatters

    private static let baseFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

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

    // MARK: Date Parsing
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

    // MARK: Formatting
    private func formatted(_ format: String) -> String {
        guard let date = toDate() else { return "" }
        return Self.formatter(for: format).string(from: date)
    }

}
