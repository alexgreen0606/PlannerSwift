//
//  routineEvents.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftUI

extension RoutineEvent {
    static func routineEvents(
        for routine: Routine,
        /// Set of routine event context IDs to exclude.
        excluding: Set<UUID> = []
    ) -> Predicate<RoutineEvent> {
        let weekdayRawValue = routine.weekdayRawValue

        return #Predicate<RoutineEvent> { routineEvent in
            if let routineEventContext = routineEvent.routineEventContext,
                let eventRoutine = routineEvent.routine
            {
                return eventRoutine.weekdayRawValue == weekdayRawValue
                    && !excluding.contains(routineEventContext.stableId)
            } else {
                return false
            }
        }
    }
}
