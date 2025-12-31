//
//  CalendarEventPositions.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import SwiftData

@Model
class CalendarEventPositions {
    
    // Maps Calendar events IDs to sortIndex values for their planner references.
    var values: [String: Double]
    
    init() {
        self.values = [:]
    }
}
