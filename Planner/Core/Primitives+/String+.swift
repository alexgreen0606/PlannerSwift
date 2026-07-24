//
//  String+Grammar.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import SwiftDate
import SwiftUI

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
