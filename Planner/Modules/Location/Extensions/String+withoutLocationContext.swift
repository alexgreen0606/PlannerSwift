//
//  String+.swift
//  Planner
//
//  Created by Alex Green on 7/30/26.
//

import Foundation

extension String {
    var withoutLocationContext: String {
        split(separator: ",", maxSplits: 1)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            ?? self
    }
}
