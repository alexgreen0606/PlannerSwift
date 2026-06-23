//
//  Routine.swift
//  Planner
//
//  Created by Alex Green on 6/18/26.
//

import SwiftData

@Model
class Routine {

    /// Note: This is required by SwiftData limitations. Query by enums is currently not supported.
    var weekdayRawValue: String = ""

    @Relationship(
        deleteRule: .nullify,
        inverse: \RoutineEvent.routine
    )
    var routineEvents: [RoutineEvent]?
    
    @Relationship(
        deleteRule: .nullify,
        inverse: \Planner.routine
    )
    var planners: [Planner]?
    
    // TODO:
    // 4. Create a function for creating all Routines as needed when app loads.
    // 5. Link a routine to each planner as it is created.

    init(weekday: Weekday) {
        weekdayRawValue = weekday.rawValue
    }
}
