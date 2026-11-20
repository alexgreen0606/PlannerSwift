//
//  DatestampFormatter.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import Foundation
import SwiftDate

enum DatestampFormatter {
    private static let formatterQueue = DispatchQueue(
        label: "datestamp.formatter.queue"
    )

    private static var formatterCache: [String: DateFormatter] = [:]

    private static func cacheKey(
        format: String,
        timeZone: TimeZone
    ) -> String {
        "\(format)|\(timeZone.identifier)"
    }

    static func formatter(
        format: String = "yyyy-MM-dd",
        timeZone: TimeZone = .current
    ) -> DateFormatter {
        let key = cacheKey(
            format: format,
            timeZone: timeZone
        )

        return formatterQueue.sync {
            if let formatter = formatterCache[key] {
                return formatter
            }

            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timeZone

            formatterCache[key] = formatter
            return formatter
        }
    }

    static func datestamp(
        from date: Date,
        format: String = "yyyy-MM-dd",
        timeZone: TimeZone = .current
    ) -> String {
        formatter(
            format: format,
            timeZone: timeZone
        ).string(from: date)
    }

    static func date(
        from datestamp: String,
        format: String = "yyyy-MM-dd",
        region: Region = .current
    ) -> Date? {
        formatter(
            format: format,
            timeZone: region.timeZone
        ).date(from: datestamp)
    }

    static func monthstamp(
        from referenceMonthstamp: String,
        offset: Int
    ) -> String? {
        guard
            let referenceDate = date(
                from: referenceMonthstamp,
                format: "yyyy-MM"
            ),
            let displayedMonth = Calendar.current.date(
                byAdding: .month,
                value: offset,
                to: referenceDate
            )
        else {
            return nil
        }

        return datestamp(
            from: displayedMonth,
            format: "yyyy-MM"
        )
    }

    static func datestamps(
        for monthstamp: String
    ) -> [String?] {
        guard
            let month = date(
                from: monthstamp,
                format: "yyyy-MM"
            )
        else {
            return []
        }

        let calendar = Calendar.current

        guard
            let firstDay = calendar.dateInterval(
                of: .month,
                for: month
            )?.start,
            let numberOfDays = calendar.range(
                of: .day,
                in: .month,
                for: firstDay
            )
        else {
            return []
        }

        let weekdayOffset =
            (calendar.component(.weekday, from: firstDay)
                - calendar.firstWeekday
                + 7) % 7

        let totalCells =
            Int(
                ceil(Double(weekdayOffset + numberOfDays.count) / 7.0)
            ) * 7

        return (0..<totalCells).map { offset in
            guard
                offset >= weekdayOffset,
                offset < weekdayOffset + numberOfDays.count,
                let date = calendar.date(
                    byAdding: .day,
                    value: offset - weekdayOffset,
                    to: firstDay
                )
            else {
                return nil
            }

            return datestamp(from: date)
        }
    }
}
