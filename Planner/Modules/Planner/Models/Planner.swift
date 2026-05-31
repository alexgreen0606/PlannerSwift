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

    @Relationship(deleteRule: .nullify, inverse: \Location.planners)
    var location: Location?

    var trip: Trip?

    var showCompleted: Bool = false

    /// When nil, it inherits from trip.
    /// If trip is nil, defaults to false.
    var excludeRoutine: Bool?

    var routineEventVariants: [RoutineEventVariant]?

    init(datestamp: String, location: Location? = nil) {
        self.datestamp = datestamp
        self.location = location
    }
}
