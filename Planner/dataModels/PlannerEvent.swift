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
    
    // Controlled by the EventModal.
    // Any changes to this value will overwrite the sortDate.
    var date: Date
    
    // Controlled by drag-and-drop.
    // May go out of sync with the date.
    var sortDate: Date
    
    // Default events to generic, untimed events.
    var hasTime: Bool = false
    
    var locationSource = LocationSource.planner
    var location: Location?

    @Transient
    var calendarEvent: EKEvent?

    init(
        date: Date,
        calendarEvent: EKEvent? = nil,
        sortIndex: Double,
    ) {
        
        let initialDate = calendarEvent?.startDate ?? date
        
        self.date = initialDate
        self.sortDate = initialDate
        
        super.init(sortIndex: sortIndex)
        
        self.calendarEvent = calendarEvent
        self.title = calendarEvent?.title ?? ""
    }
}
