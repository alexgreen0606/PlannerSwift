//
//  String+DatestampFormatting.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import Foundation
import SwiftDate

extension String {
    private func formatted(
        _ format: String
    ) -> String {
        guard let date else { return "" }

        return
            DatestampFormatter
                .formatter(for: format)
                .string(from: date)
    }

    // MARK: - Base Date Formats

    /// Example: "06.calendar"
    var calendarSymbolName: String {
        "\(suffix(2)).calendar"
    }

    /// Example: "06"
    var monthDigit: String {
        split(separator: "-")[1].description
    }

    /// Example: "Tuesday"
    var weekday: String {
        formatted("EEEE")
    }

    /// Example: "2000"
    var year: String {
        let components = split(separator: "-")
        guard components.count >= 1 else { return "" }
        return String(components[0])
    }

    /// Example: "June 6"
    var dateWithoutYear: String {
        formatted("MMMM d")
    }

    /// Example: "June 6, 2000"
    var dateWithYear: String {
        formatted("MMMM d, yyyy")
    }

    /// Example: "June 6", "June 6, 2000"
    func dateLabel(todaystamp: String) -> String {
        let thisYear = String(todaystamp.prefix(4))
        let year = String(prefix(4))
        return year == thisYear ? dateWithoutYear : dateWithYear
    }

    // MARK: - Concise Variants

    /// Example: "TUE"
    var conciseWeekday: String {
        formatted("EEE").uppercased()
    }

    /// Example: "JUN"
    var conciseMonth: String {
        formatted("MMM").uppercased()
    }

    /// Example: "Jun 6"
    var conciseDateWithoutYear: String {
        formatted("MMM d")
    }

    /// Example: "Jun 6, 2000"
    var conciseDateWithYear: String {
        formatted("MMM d, yyyy")
    }

    /// Example: "Jun 6", "Jun 6, 2000"
    func conciseDateLabel(todaystamp: String) -> String {
        let thisYear = String(todaystamp.prefix(4))
        let year = String(prefix(4))
        return year == thisYear ? conciseDateWithoutYear : conciseDateWithYear
    }
}
