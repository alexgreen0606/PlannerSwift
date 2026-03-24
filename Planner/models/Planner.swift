//
//  Planner.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftData

// Clean

// TODO: allow hideRoutines to be nil. Default. When it is hard-set, use it. Otherwise pull from a trip
// if one exists. If it doesnt exist, consider it false.

@Model
class Planner {
    
    // Converts to the start of day (Date) based on the planner's location (TimeZone).
    @Attribute(.unique) var datestamp: String
    
    var showChecked: Bool = false
    
    var trip: Trip? = nil
    
    @Relationship(deleteRule: .nullify, inverse: \Location.planners)
    var location: Location?
    
    init(datestamp: String, location: Location?) {
        self.datestamp = datestamp
        self.location = location
    }
}
