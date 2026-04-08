//
//  PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import Foundation
import SwiftData

// Clean

@available(iOS 26.0, *)
@Model
class PlannerEvent: EventListItem {

    var date: Date
    var hasTime: Bool = false
    var isCanceled: Bool = false
    
    @Relationship(deleteRule: .nullify, inverse: \Location.events)
    var location: Location?

    @Transient
    var calendarEvent: EKEvent?
    
    var calendarItemExternalIdentifier: String?
    
    // Uniquely identifies recurring event occurrences (calendar events only).
    @Attribute(.unique) var occurrenceId: String?

    init(
        date: Date,
        sortDate: Date,
        calendarEvent: EKEvent? = nil,
    ) {
        self.date = date

        super.init(sortDate: sortDate)
        
        // Calendar event synchronization.
        if let calendarEvent {
            self.date = calendarEvent.startDate
            self.calendarEvent = calendarEvent
            self.title = calendarEvent.title
            self.calendarItemExternalIdentifier = calendarEvent.calendarItemExternalIdentifier
            self.occurrenceId = calendarEvent.occurrenceId
            self.location = calendarEvent.location(storageEvent: nil)
            self.hasTime = true
        }

    }
}
