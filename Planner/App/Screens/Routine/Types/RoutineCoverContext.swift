//
//  RoutineCoverContext.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

struct RoutineCoverContext: Identifiable {
    var weekday: Weekday

    var id: String {
        String(weekday.rawValue)
    }
}
