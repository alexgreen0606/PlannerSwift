////
////  DatestampFormatter.swift
////  Planner
////
////  Created by Alex Green on 5/14/26.
////

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
        region: Region = .current
    ) -> String {
        formatter(
            timeZone: region.timeZone
        ).string(from: date)
    }

    static func date(
        from datestamp: String,
        region: Region = .current
    ) -> Date? {
        formatter(
            timeZone: region.timeZone
        ).date(from: datestamp)
    }
}
