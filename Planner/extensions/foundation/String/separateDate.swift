//
//  separateDate.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import Foundation
import SwiftDate

extension String {

    // Any user input expected.
    func separateDate(for plannerDay: DateInRegion) -> (
        date: Date, updatedText: String
    )? {

        // Matches times like "9 AM", "9:30 pm", and "12:05 PM".
        let pattern = #"\b(1[0-2]|[1-9])(?::([0-5][0-9]))?\s?(AM|PM|am|pm)\b"#

        // Search for a time value.
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range),
            let matchRange = Range(match.range, in: self)
        else { return nil }
        let fullMatch = String(self[matchRange])

        // Separate time components.
        guard let hourPart = Int(self[Range(match.range(at: 1), in: self)!])
        else { return nil }
        let minutePart =
            match.range(at: 2).location != NSNotFound
            ? Int(self[Range(match.range(at: 2), in: self)!]) ?? 0
            : 0
        let periodPart = String(self[Range(match.range(at: 3), in: self)!])
            .uppercased()
        var hour = hourPart % 12
        if periodPart == "PM" { hour += 12 }

        // Build the final date relative to plannerDay.
        var components = plannerDay.dateComponents
        components.hour = hour
        components.minute = minutePart
        components.second = 0

        guard let finalDate = plannerDay.calendar.date(from: components)
        else {
            return nil
        }

        return (
            date: finalDate,
            updatedText: self.replacingOccurrences(of: fullMatch, with: "")
        )
    }

}
