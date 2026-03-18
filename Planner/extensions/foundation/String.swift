//
//  String.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import Foundation
import SwiftDate

extension String {

    var capitalizedFirst: String {
        guard let first = self.first else { return self }
        return first.uppercased() + self.dropFirst()
    }

    // Expects YYYY-MM-DD format.
    var shortMonth: String {  // Ex: DEC
        self
            .toDate("yyyy-MM-dd", region: .local)?
            .toFormat("MMM")
            .uppercased()
            ?? "???"
    }

    // Expects YYYY-MM-DD format.
    var year: String {  // Ex: 2028
        self
            .toDate("yyyy-MM-dd", region: .local)?
            .toFormat("YYYY")
            .uppercased()
            ?? "???"
    }

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
        self.toDate("yyyy-MM-dd", region: region)?.dateAtStartOf(.day)
    }

    // Expect 24-hour HH:MM format.
    func toDate(for startOfDay: DateInRegion) -> Date? {
        "\(startOfDay.datestamp) \(self)"
            .toDate("yyyy-MM-dd HH:mm", region: startOfDay.region)?
            .date
    }

    // Any user input expected.
    func separateDate(for plannerStartOfDay: DateInRegion) -> (
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

        // Build the final date relative to plannerStartOfDay.
        var components = plannerStartOfDay.dateComponents
        components.hour = hour
        components.minute = minutePart
        components.second = 0

        guard let finalDate = plannerStartOfDay.calendar.date(from: components)
        else {
            return nil
        }

        return (
            date: finalDate,
            updatedText: self.replacingOccurrences(of: fullMatch, with: "")
        )
    }

}
