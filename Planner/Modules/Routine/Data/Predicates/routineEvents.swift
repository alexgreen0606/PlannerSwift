//
//  routineEvents.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftUI

extension RoutineEvent {
    static func routineEvents(
        for routine: Routine
    ) -> Predicate<RoutineEvent> {
        let weekdayRawValue = routine.weekdayRawValue
        
        return #Predicate<RoutineEvent> {
            if let eventRoutine = $0.routine {
                return eventRoutine.weekdayRawValue == weekdayRawValue
            } else {
                return false
            }
        }
    }
}
