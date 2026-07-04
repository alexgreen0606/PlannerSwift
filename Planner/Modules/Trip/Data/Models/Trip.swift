//
//  Trip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftData

@Model
class Trip {
    
    var title: String = ""
    var excludeRoutines: Bool = true

    /// SwiftData query helpers.

    var firstDatestamp: String = ""
    var lastDatestamp: String = ""
    
    // MARK: Sibling
    var location: Location?
    
    // MARK: Sibling
    @Relationship(inverse: \Planner.trip)
    var planners: [Planner]?

    init() {}
}
