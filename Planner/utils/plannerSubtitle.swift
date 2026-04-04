//
//  plannerSubtitle.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftDate

// Clean

// TODO: move this if only references once
func plannerSubtitle(datestamp: String, todaystamp: String) -> String {
    datestamp.proximityFormat(
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
                format: .countdown
            ),
        ],
        todaystamp: todaystamp
    )
}
