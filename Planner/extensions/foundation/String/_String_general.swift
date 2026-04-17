//
//  _general.swift
//  Planner
//
//  Created by Alex Green on 4/4/26.
//

import Foundation
import SwiftDate

extension String {

    // Removes whitespace padding and enforces 2 chars.
    var querySanitized: String {
        let trimmed =
            self
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.count == 1 {
            return ""
        }

        return trimmed.lowercased()
    }

    func pluralized(from itemCount: Int) -> String {
        "\(self)\(itemCount == 1 ? "" : "s")"
    }

}
