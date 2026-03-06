//
//  Planner.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftData

// Clean

@Model
class Planner {
    
    // Converts to the start of day (Date) based on the planner's location (TimeZone).
    @Attribute(.unique) var datestamp: String
    
    var showCompleted: Bool = false
    var showCanceled: Bool = false
    
    @Relationship(deleteRule: .nullify)
    var location: Location?
    
    init(datestamp: String, location: Location?) {
        self.datestamp = datestamp
        self.location = location
    }
}
