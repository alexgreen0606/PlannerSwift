//
//  StringExtension+Planner.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import SwiftUI

extension String {
    /// Removes whitespace padding and enforces 2 chars.
    var querySanitized: String {
        let trimmed =
            trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count == 1 {
            return ""
        }

        return trimmed.lowercased()
    }
}
