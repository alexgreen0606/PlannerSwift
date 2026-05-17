//
//  DatestampFormatter.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import SwiftUI

enum DatestampFormatter {

    private static var formatterCache: [String: DateFormatter] = [:]
    private static let formatterQueue = DispatchQueue(
        label: "formatter.cache.queue"
    )

    private static let baseFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func formatter(for format: String) -> DateFormatter {
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

    static func parseDatestamp(
        _ value: String
    ) -> Date? {
        baseFormatter.date(from: value)
    }

}
