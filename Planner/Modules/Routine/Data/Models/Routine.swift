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

    // MARK: Sibling
    @Relationship(
        deleteRule: .nullify,
        inverse: \RoutineEvent.routine
    )
    var routineEvents: [RoutineEvent]?
    
    // MARK: Sibling
    @Relationship(
        deleteRule: .nullify,
        inverse: \Planner.routine
    )
    var planners: [Planner]?

    init(weekdayRawValue: String) {
        self.weekdayRawValue = weekdayRawValue
    }
}
