//
//  getThisWeekDatestamps.swift
//  Planner
//
//  Created by Alex Green on 5/15/26.
//

import SwiftDate
import SwiftUI

func getThisWeekDatestamps() -> [String] {
    (0 ..< 7).map {
        DateInRegion(Date(), region: .local)
            .dateByAdding($0, .day)
            .toFormat("yyyy-MM-dd")
    }.sorted()
}
