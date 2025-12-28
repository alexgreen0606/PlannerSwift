//
//  CalendarEventPositions.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import SwiftData

@Model
class CalendarEventPositions {
    var values: [String: Double]
    
    init() {
        self.values = [:]
    }
}
