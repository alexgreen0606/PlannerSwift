//
//  String+TimeExtraction.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import Foundation
import SwiftDate

extension String {
    /// Matches times like "9 AM", "9:30 pm", and "12:05 PM".
    private static let timeRegex = try! NSRegularExpression(
        pattern: #"\b(1[0-2]|[1-9])(?::([0-5][0-9]))?\s?(AM|PM|am|pm)\b"#
    )

    /// Parses a 12-hour time expression from freeform text.
    ///
    /// Examples:
    /// - "Dinner 7 PM"
    /// - "Meeting 9:30 am"
    ///
    /// Returns the resolved date relative to `plannerDay` and the
    /// remaining text with the matched time removed.
    func extractTime(for plannerDay: DateInRegion) -> (
        date: Date, updatedText: String
    )? {

        // MARK: Search for a time value.

        let range = NSRange(startIndex..<endIndex, in: self)

        guard let match = Self.timeRegex.firstMatch(in: self, range: range),
            let matchRange = Range(match.range, in: self)
        else { return nil }

        let fullMatch = String(self[matchRange])

        // MARK: Separate time components.

        guard let hourPart = Int(self[Range(match.range(at: 1), in: self)!])
        else { return nil }

        let minute =
            match.range(at: 2).location != NSNotFound
            ? Int(self[Range(match.range(at: 2), in: self)!]) ?? 0
            : 0

        let periodPart = String(self[Range(match.range(at: 3), in: self)!])
            .uppercased()

        let hour = (hourPart % 12) + (periodPart == "PM" ? 12 : 0)

        // MARK: Build the final date relative to plannerDay.

        var components = plannerDay.dateComponents
        components.hour = hour
        components.minute = minute
        components.second = 0

        guard let finalDate = plannerDay.calendar.date(from: components)
        else {
            return nil
        }

        return (
            date: finalDate,
            updatedText: replacingOccurrences(of: fullMatch, with: "")
        )
    }
}
