//
//  ProximityRule.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

struct ProximityRule {
    let proximity: TodayProximity
    let format: DateFormat
    let ordinal: Bool

    init(proximity: TodayProximity, format: DateFormat, ordinal: Bool = false) {
        self.proximity = proximity
        self.format = format
        self.ordinal = ordinal
    }
}
