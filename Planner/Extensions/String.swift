//
//  String.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import Foundation
import SwiftDate

extension String {

    // Expects YYYY-MM-DD format.
    func toCalendarSymbolName() -> String {
        let dd = self.suffix(2)

        let ddInt = Int(dd)
        if ddInt == nil || ddInt! < 1 || ddInt! > 31 {
            return "note"
        }

        return "\(dd).calendar"
    }

    // Expect ISO timestamp format.
    func toTimeValues() -> (time: String, indicator: String)? {
        guard let date = self.toISODate()?.convertTo(region: .current) else {
            return nil
        }

        let formatted = date.toFormat("h:mm a")
        let parts = formatted.split(separator: " ")
        guard parts.count == 2 else { return nil }

        return (String(parts[0]), String(parts[1]))
    }

    // Expect 24-hour HH:MM format.
    func toIso(usingDate datestamp: String) -> String? {
        let combined = "\(datestamp) \(self)"
        guard
            let localDate = combined.toDate(
                "yyyy-MM-dd HH:mm",
                region: .current
            )
        else { return nil }

        // Convert to UTC ISO string
        return localDate.convertTo(region: .UTC).toISO()
    }

    // Expect 24-hour HH:MM format.
    func toPlannerEventTimeConfig(usingDate datestamp: String) -> TimeConfig? {
        guard let iso = self.toIso(usingDate: datestamp) else { return nil }
        return TimeConfig(startIso: iso)
    }

    // Expect any lexographical time string format.
    func isEarlierOrEqual(to other: String) -> Bool {
        return self <= other
    }

    // Any user input expected.
    func separateTimeValue() -> (
        timeValue24Hour: String, updatedText: String
    )? {
        // Regex to match times like "9 AM", "9:30 pm", "12:05 PM"
        let pattern = #"\s+(1[0-2]|[1-9])(?::([0-5][0-9]))?\s?(AM|PM|am|pm)\b"#

        // Retrieve the time value (if one exists).
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(self.startIndex..<self.endIndex, in: self)
        guard let match = regex.firstMatch(in: self, range: range),
            let matchRange = Range(match.range, in: self)
        else { return nil }
        let fullMatch = String(self[matchRange])

        let hourPart = String(self[Range(match.range(at: 1), in: self)!])
        let minutePart =
            match.range(at: 2).location != NSNotFound
            ? String(self[Range(match.range(at: 2), in: self)!])
            : "00"
        let periodPart = String(self[Range(match.range(at: 3), in: self)!])
            .uppercased()
        let timeString = "\(hourPart):\(minutePart) \(periodPart)"
        guard let date = timeString.toDate("h:mm a", region: .current) else {
            return nil
        }

        // Assemble the filtered text and time value.
        let timeValue24Hour = date.toFormat("HH:mm")
        let updatedText = self.replacingOccurrences(of: fullMatch, with: "")
        return (timeValue24Hour: timeValue24Hour, updatedText: updatedText)
    }
}
