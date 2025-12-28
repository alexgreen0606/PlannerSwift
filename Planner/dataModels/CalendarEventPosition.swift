//
//  CalendarEventPosition.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import SwiftData

@Model
class CalendarEventPosition {
    var eventId: String
    var sortIndex: Double
    
    init(eventId: String, sortIndex: Double) {
        self.eventId = eventId
        self.sortIndex = sortIndex
    }
}
