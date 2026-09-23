//
//  getThisWeekDatestamps.swift
//  Planner
//
//  Created by Alex Green on 9/22/26.
//

import SwiftDate
import Foundation

func getThisWeekDatestamps() -> [String] {
    (0..<7).map { offset in
        DateInRegion(region: .local)
            .dateByAdding(offset, .day)
            .datestamp
    }
}
