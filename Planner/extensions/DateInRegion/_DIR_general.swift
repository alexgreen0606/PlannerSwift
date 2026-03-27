//
//  _DIR_general.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftDate
import SwiftUI

// Clean

extension DateInRegion {

    var startOfDay: DateInRegion {
        self.dateAt(.startOfDay)
    }

    // True if between Today and the next 6 days.
    var isNext7Days: Bool {
        let startOfDay = self.dateAt(.startOfDay)
        let startOfToday = DateInRegion(region: .local).dateAt(.startOfDay)

        if startOfDay < startOfToday {
            return false
        }

        let daysFromToday =
            startOfDay.difference(in: .day, from: startOfToday) ?? 0
        if daysFromToday <= 6 {
            return true
        }

        return false
    }

    // True if Yesterday, Today, or Tomorrow.
    var isWithinADay: Bool {
        let todaystamp = DateInRegion(Date(), region: .local).datestamp

        guard let dayDiff = dayDifference(from: datestamp, to: todaystamp)
        else {
            return false
        }

        return abs(dayDiff) < 2
    }

}
