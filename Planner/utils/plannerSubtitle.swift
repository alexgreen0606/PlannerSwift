//
//  plannerSubtitle.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftDate

// Clean

func plannerSubtitle(day: DateInRegion) -> String {
    day.proximityFormat(
        using: [
            ProximityRule(
                proximity: .withinADay,
                format: .weekday
            ),
            ProximityRule(
                proximity: .next7Days,
                format: .countdown
            ),
            ProximityRule(
                proximity: .fallback,
                format: .weekday
            ),
        ]
    )
}
