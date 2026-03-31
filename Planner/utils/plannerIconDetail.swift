//
//  plannerIconDetail.swift
//  Planner
//
//  Created by Alex Green on 3/31/26.
//

import SwiftDate

// Clean

func plannerIconDetail(day: DateInRegion) -> String {
    day.proximityFormat(
        using: [
            ProximityRule(
                proximity: .withinADay,
                format: .shortMonth
            ),
            ProximityRule(
                proximity: .next7Days,
                format: .shortMonth
            ),
            ProximityRule(
                proximity: .fallback,
                format: .shortWeekday
            ),
        ]
    )
}
