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
    var shortMonth: String {  // Ex: DEC
        self
            .toDate("yyyy-MM-dd", region: .local)?
            .toFormat("MMM")
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
    var date: Date? {
        self.toDate("yyyy-MM-dd", region: .local)?.date
    }
    
    // Expects YYYY-MM-DD format.
    var dateInLocalRegion: DateInRegion? {
        self.toDate("yyyy-MM-dd", region: .local)
    }

    // Expect 24-hour HH:MM format.
    func toDate(for datestamp: String) -> Date? {
        let dateTime = "\(datestamp) \(self)"
        return dateTime.toDate("yyyy-MM-dd HH:mm", region: .local)?.date
    }

    // Any user input expected.
    func separateTimeValue() -> (
        timeValue24Hour: String, updatedText: String
    )? {  // Ex: (13:45, sample user input)
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
        guard let date = timeString.toDate("h:mm a", region: .local) else {
            return nil
        }

        // Assemble the filtered text and time value.
        let timeValue24Hour = date.toFormat("HH:mm")
        let updatedText = self.replacingOccurrences(of: fullMatch, with: "")
        return (timeValue24Hour: timeValue24Hour, updatedText: updatedText)
    }

    var capitalizedFirst: String {
        guard let first = self.first else { return self }
        return first.uppercased() + self.dropFirst()
    }
}
