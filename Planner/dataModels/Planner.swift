//
//  Planner.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftData

@Model
class Planner {
    
    // Converts to the start of day based on the planner's location.
    @Attribute(.unique) var datestamp: String
    
    var showCompleted: Bool = false
    var showCanceled: Bool = false
    
    var locationSource = LocationSource.home
    
    @Relationship(deleteRule: .cascade)
    var location: Location?
    
    init(datestamp: String, location: Location?) {
        self.datestamp = datestamp
        self.location = location
    }
}
