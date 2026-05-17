//
//  proximityFormat.swift
//  Planner
//
//  Created by Alex Green on 4/9/26.
//

import Foundation
import SwiftDate

extension String {
    /// Formats date strings based on their proximity to today.
    func proximityFormat(
        using rules: [ProximityRule],
        todaystamp: String
    ) -> String {
        for rule in rules {
            if rule.proximity.matches(self, todaystamp: todaystamp) {
                return rule.format.string(
                    from: self,
                    todaystamp: todaystamp,
                    ordinal: rule.ordinal
                )
            }
        }
        return ""
    }
}
