//
//  routineEventInstances.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftUI

extension RoutineEventWeekdayInstance {
    static func instances(
        for weekday: Weekday
    ) -> Predicate<RoutineEventWeekdayInstance> {
        let weekdayRawValue = weekday.rawValue

        return #Predicate<RoutineEventWeekdayInstance> {
            $0.weekdayRawValue == weekdayRawValue
        }
    }
}
