//
//  plannerIconFormat.swift
//  Planner
//
//  Created by Alex Green on 3/31/26.
//

import SwiftDate

// Clean

func plannerIconFormat(datestamp: String, todaystamp: String) -> DateFormat {
    if datestamp.isNext7Days(todaystamp: todaystamp)
        || datestamp.isWithinADay(todaystamp: todaystamp)
    {
        return .shortMonth
    }
    return .shortWeekday
}
