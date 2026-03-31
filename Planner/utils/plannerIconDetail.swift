//
//  plannerIconFormat.swift
//  Planner
//
//  Created by Alex Green on 3/31/26.
//

import SwiftDate

// Clean

func plannerIconFormat(day: DateInRegion) -> DateFormat {
    if day.isNext7Days || day.isWithinADay {
        return .shortMonth
    }
    return .shortWeekday
}
