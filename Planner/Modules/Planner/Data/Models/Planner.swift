//
//  Planner.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftData

@Model
class Planner {

    /// Converts to the start of day (DateInRegion) based on the planner's time zone.
    var datestamp: String = ""

    var showCompleted: Bool = false

    /// When nil, it inherits from trip.
    /// If trip is nil, defaults to false.
    var excludeRoutine: Bool?
    
    // MARK: Sibling
    var location: Location?
    
    // MARK: Sibling
    var routine: Routine?
    
    // MARK: Sibling
    var trip: Trip?

    // MARK: Children
    @Relationship(deleteRule: .cascade, inverse: \RoutineEventRecordContext.planner)
    var routineEventRecordContexts: [RoutineEventRecordContext]?

    init(datestamp: String, routine: Routine, location: Location? = nil) {
        self.datestamp = datestamp
        self.routine = routine
        self.location = location
        
        routine.planners.safeAppend(self)
    }
}
