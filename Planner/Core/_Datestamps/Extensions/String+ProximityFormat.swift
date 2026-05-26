//
//  String+ProximityFormat.swift
//  Planner
//
//  Created by Alex Green on 4/9/26.
//

extension String {
    /// Formats datestamps based on their proximity to today.
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
