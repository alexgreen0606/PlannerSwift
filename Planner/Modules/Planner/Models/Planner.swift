//
//  Planner.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftData
import SwiftUI

// Clean

@Model
class Planner {
    /// Converts to the start of day (Date) based on the planner's location (TimeZone).
    var datestamp: String = ""

    var showChecked: Bool = false

    /// When nil, it inherits from trip.
    /// If trip is nil, defaults to false.
    var excludeRoutine: Bool?

    var routineEventVariants: [RoutineEventVariant]?

    var trip: Trip?

    @Relationship(deleteRule: .nullify, inverse: \Location.planners)
    var location: Location?

    init(datestamp: String, location: Location?) {
        self.datestamp = datestamp
        self.location = location
    }
}
