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

@available(iOS 26.0, *)
@Model
class PlannerEvent: EventListItem {
    /// Must be set when an event doesn't have a time.
    var datestamp: String?

    @Relationship(deleteRule: .nullify, inverse: \Location.events)
    var location: Location?

    @Transient
    var calendarEvent: EKEvent?

    var calendarItemExternalIdentifier: String?

    var routineEvent: RoutineEvent?

    var routineEventVariant: RoutineEventVariant?

    /// Uniquely identifies recurring event occurrences (calendar events only).
    var occurrenceId: String?

    init(
        time: Date? = nil,
        datestamp: String? = nil,
        sortDate: Date,
        calendarEvent: EKEvent? = nil,
        routineEvent: RoutineEvent? = nil,
        startOfDay: DateInRegion? = nil
    ) {
        self.datestamp = datestamp
        super.init(sortDate: sortDate)
        self.time = time

        // Calendar event synchronization.
        if let calendarEvent {
            title = calendarEvent.title
            self.time = calendarEvent.startDate
            self.calendarEvent = calendarEvent
            calendarItemExternalIdentifier =
                calendarEvent.calendarItemExternalIdentifier
            occurrenceId = calendarEvent.occurrenceId
            location = calendarEvent.location(storageEvent: nil)
            return
        }

        // Routine event synchronization.
        if let routineEvent {
            title = routineEvent.title

            if let startOfDay,
               let time = routineEvent.date(in: startOfDay)
            {
                self.time = time
            }

            self.routineEvent = routineEvent
            routineEvent.syncedSortDatePlannerEventIds.insert(stableId)
        }
    }
}
