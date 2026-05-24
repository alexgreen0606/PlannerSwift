//
//  Trip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftData
import SwiftDate
import SwiftUI

@Model
class Trip {
    var title: String = ""

    @Relationship(inverse: \Planner.trip)
    var planners: [Planner]?

    /// SwiftData query helpers.
    var firstDatestamp: String = ""
    var lastDatestamp: String = ""

    @Relationship(deleteRule: .nullify, inverse: \Location.trips)
    var location: Location?

    var excludeRoutines: Bool = true

    init() {}
}
