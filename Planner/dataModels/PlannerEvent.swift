//
//  PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import Foundation
import SwiftData

@available(iOS 26.0, *)
@Model
class PlannerEvent: ListItem {
    var date: Date
    
    // Default events to generic, untimed events.
    var untimed: Bool = true

    @Transient
    var calendarEvent: EKEvent? = nil

    init(
        date: Date,
        calendarEvent: EKEvent? = nil,
        sortIndex: Double,
    ) {
        self.date = calendarEvent?.startDate ?? date // TODO: use end date if needed
        
        super.init(sortIndex: sortIndex)
        
        self.calendarEvent = calendarEvent
        self.title = calendarEvent?.title ?? ""
    }
}
