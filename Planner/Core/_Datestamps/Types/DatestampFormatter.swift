////
////  DatestampFormatter.swift
////  Planner
////
////  Created by Alex Green on 5/14/26.
////
//
//import SwiftUI
//
//enum DatestampFormatter {
//    private static var formatterCache: [String: DateFormatter] = [:]
//    private static let formatterQueue = DispatchQueue(
//        label: "formatter.cache.queue"
//    )
//
//    private static let baseFormatter: DateFormatter = {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd"
//        formatter.locale = Locale(identifier: "en_US_POSIX")
//        return formatter
//    }()
//
//    static func formatter(for format: String) -> DateFormatter {
//        formatterQueue.sync {
//            if let cached = formatterCache[format] {
//                return cached
//            }
//
//            let formatter = DateFormatter()
//            formatter.dateFormat = format
//            formatter.locale = Locale.current
//
//            formatterCache[format] = formatter
//            return formatter
//        }
//    }
//
//    static func date(
//        for datestamp: String
//    ) -> Date? {
//        baseFormatter.date(from: datestamp)
//    }
//}

//
//  DatestampFormatter.swift
//  Planner
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
        region: Region = .current
    ) -> String {
        formatter(
            timeZone: region.timeZone
        ).string(from: date)
    }

    /// Note: The region of this date is not specific/customizable. Don't use this for any region-specific logic.
    static func date(
        from datestamp: String
    ) -> Date? {
        formatter(
            timeZone: TimeZone(secondsFromGMT: 0)!
        ).date(from: datestamp)
    }
}
