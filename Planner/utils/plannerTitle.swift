//
//  plannerTitle.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftDate

// Clean

func plannerTitle(day: DateInRegion) -> String {
    day.proximityFormat(
        using: [
            ProximityRule(
                proximity: .withinADay,
                format: .countdown
            ),
            ProximityRule(
                proximity: .next7Days,
                format: .weekday
            ),
            ProximityRule(
                proximity: .fallback,
                format: .dateLabel
            ),
        ]
    )
}
