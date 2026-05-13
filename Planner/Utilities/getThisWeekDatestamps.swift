//
//  getThisWeekDatestamps.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import SwiftDate
import SwiftUI

// Clean

func getThisWeekDatestamps() -> [String] {
    (0..<7).map {
        DateInRegion(Date(), region: .local)
            .dateByAdding($0, .day)
            .toFormat("yyyy-MM-dd")
    }.sorted()
}
