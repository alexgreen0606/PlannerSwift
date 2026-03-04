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

    // Controlled by drag-and-drop.
    // May go out of sync with the date.
    var sortDate: Date

    // Default events to generic, untimed events.
    var hasTime: Bool = false
    
    // MUST exist when hasTime is true.
    @Relationship(deleteRule: .nullify)
    var location: Location?

    @Transient
    var calendarEvent: EKEvent?
    
    var calendarItemExternalIdentifier: String?
    
    // Uniquely identifies recurring event occurences (Calendar Events only).
    var occurrenceId: String?

    init(
        date: Date,
        sortDate: Date,
        calendarEvent: EKEvent? = nil,
    ) {
        self.date = date
        self.sortDate = sortDate

        super.init(sortIndex: 0)
        
        // Handle calendar event synchronization.
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
