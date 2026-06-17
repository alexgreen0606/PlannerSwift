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

@Model
class PlannerEvent: EventListItem {

    var stableId: UUID = UUID()

    var title: String = ""
    var time: Date?

    @Relationship(deleteRule: .nullify, inverse: \Location.events)
    var location: Location?

    /// Must be set when an event doesn't have a time.
    var datestamp: String?

    /// Controlled by drag-and-drop.
    /// No relation to the event's time.
    var sortDate: Date = Date.now

    var isCompleted: Bool = false

    var height: CGFloat = 0

    @Relationship(
        deleteRule: .cascade,
        inverse: \EKEventContext.plannerEvent
    )
    var eKEventContext: EKEventContext?

    var routineEvent: RoutineEvent?
    var routineEventVariant: RoutineEventVariant?
    var routineEventWeekdayInstance: RoutineEventWeekdayInstance?

    // MARK: Calendar Event
    init(ekEvent: EKEvent, sortDate: Date) {
        title = ekEvent.title
        time = ekEvent.startDate
        location = ekEvent.location()
        self.sortDate = sortDate
        eKEventContext = EKEventContext(ekEvent: ekEvent)
    }

    // MARK: Routine Event
    init(routineEvent: RoutineEvent, startOfDay: DateInRegion, sortDate: Date) {
        title = routineEvent.title

        if let time = routineEvent.date(on: startOfDay) {
            self.time = time
        } else {
            datestamp = startOfDay.datestamp
        }

        self.sortDate = sortDate
        self.routineEvent = routineEvent

        routineEvent.syncedSortDatePlannerEventIds.insert(stableId)
    }

    // MARK: Untimed Event
    init(datestamp: String, sortDate: Date) {
        self.datestamp = datestamp
        self.sortDate = sortDate
    }
}
