//
//  PlannerBounds.swift
//  Planner
//
//  Created by Alex Green on 11/19/26.
//

import SwiftDate
import SwiftUI

struct PlannerBounds {
    let minStartOfDay: DateInRegion
    let maxStartOfDay: DateInRegion

    var endOfBounds: Date {
        maxStartOfDay.dateByAdding(1, .day).date
    }

    func containsDate(_ date: Date) -> Bool {
        date >= minStartOfDay.date
            && date < endOfBounds
    }

    func containsDatestamp(_ datestamp: String) -> Bool {
        datestamp >= minStartOfDay.datestamp
            && datestamp <= maxStartOfDay.datestamp
    }

    func containsDateRange(startDate: Date, endDate: Date) -> Bool {
        startDate < endOfBounds
            && endDate > minStartOfDay.date
    }

    func containsDatestampRange(
        startDatestamp: String,
        endDatestamp: String
    ) -> Bool {
        startDatestamp <= maxStartOfDay.datestamp
            && endDatestamp >= minStartOfDay.datestamp
    }
}
