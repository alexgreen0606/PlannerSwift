//
//  PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import Foundation
import SwiftData
import SwiftDate

// Clean

@available(iOS 26.0, *)
@Model
class PlannerEvent: EventListItem {

    var date: Date = Date()
    var hasTime: Bool = false
    var isCanceled: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Location.events)
    var location: Location?

    @Transient
    var calendarEvent: EKEvent?

    var calendarItemExternalIdentifier: String?

    var routineEvent: RoutineEvent?

    var isRoutineEventException: Bool = false

    // Uniquely identifies recurring event occurrences (calendar events only).
    var occurrenceId: String?

    init(
        date: Date,
        sortDate: Date,
        calendarEvent: EKEvent? = nil,
        routineEvent: RoutineEvent? = nil,
        plannerDay: DateInRegion? = nil
    ) {
        self.date = date

        super.init(sortDate: sortDate)

        // Calendar event synchronization.
        if let calendarEvent {
            self.title = calendarEvent.title
            self.date = calendarEvent.startDate
            self.calendarEvent = calendarEvent
            self.calendarItemExternalIdentifier =
                calendarEvent.calendarItemExternalIdentifier
            self.occurrenceId = calendarEvent.occurrenceId
            self.location = calendarEvent.location(storageEvent: nil)
            self.hasTime = true
            return
        }

        if let routineEvent {
            self.title = routineEvent.title

            if let plannerDay,
                let time = routineEvent.date(in: plannerDay)
            {
                self.date = time
                self.hasTime = true
            } else {
                self.hasTime = false
            }

            self.routineEvent = routineEvent
            routineEvent.syncedSortDatePlannerEventIds.insert(self.stableId)
        }
    }
}
