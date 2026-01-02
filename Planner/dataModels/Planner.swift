//
//  Planner.swift
//  Planner
//
//  Created by Alex Green on 12/22/25.
//

import SwiftData

@Model
class Planner {
    @Attribute(.unique) var datestamp: String
    var showCompleted: Bool = false
    var showCanceled: Bool = false

    @Relationship(deleteRule: .cascade)
    var events = [PlannerEvent]()
    
    init(datestamp: String) {
        self.datestamp = datestamp
        self.events = []
    }
}
