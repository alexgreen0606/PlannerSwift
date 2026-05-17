//
//  String+Grammar.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import SwiftDate

extension String {
    /// Returns a grammatically correct pluralized string for the given count.
    ///
    /// Example:
    /// - "1 event"
    /// - "2 events"
    func inflected(for count: Int) -> String {
        "^[\(count) \(self)](inflect: true)"
    }
}
