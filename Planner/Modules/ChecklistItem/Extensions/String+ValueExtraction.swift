//
//  String+ValueExtraction.swift
//  Planner
//
//  Created by Alex Green on 9/25/26.
//

import Foundation
import SwiftDate

extension String {
    /// Matches dollar values like "$95.01", "-$1.75", "$10", and "-$10".
    private static let valueRegex = try! NSRegularExpression(
        pattern: #"-?\$\d+(?:\.\d+)?"#
    )

    /// Parses a decimal dollar value from freeform text.
    ///
    /// Examples:
    /// - "Book -$1.75"
    /// - "Paycheck $95.01"
    ///
    /// Returns the resolved value and the remaining text with the matched value removed.
    func extractValue() -> (
        value: Decimal, updatedText: String
    )? {
        // MARK: Search for a value.

        let range = NSRange(startIndex..<endIndex, in: self)

        guard let match = Self.valueRegex.firstMatch(in: self, range: range),
            let matchRange = Range(match.range, in: self)
        else { return nil }

        let fullMatch = String(self[matchRange])

        // Create the decimal.

        let numericValue = fullMatch.replacingOccurrences(of: "$", with: "")

        guard let value = Decimal(string: numericValue)
        else { return nil }

        return (
            value: value,
            updatedText: replacingOccurrences(of: fullMatch, with: "")
        )
    }
}
