//
//  TodayProximity.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

enum TodayProximity {
    case withinADay
    case next7Days
    case fallback

    func matches(_ datestamp: String, todaystamp: String) -> Bool {
        switch self {
        case .withinADay:
            return datestamp.isWithinADay(todaystamp: todaystamp)
        case .next7Days:
            return datestamp.isNext7Days(todaystamp: todaystamp)
        case .fallback:
            return true
        }
    }
}
