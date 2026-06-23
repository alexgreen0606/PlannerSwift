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

    @Relationship(
        deleteRule: .cascade,
        inverse: \EKEventContext.plannerEvent
    )
    var eKEventContext: EKEventContext?

    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEventRecordContext.plannerEvent
    )
    var routineEventRecordContext: RoutineEventRecordContext?

    var stableId: UUID = UUID()

    var title: String = ""
    var time: Date?

    @Relationship(deleteRule: .nullify, inverse: \Location.events)
    var location: Location?

    var isCompleted: Bool = false

    /// Must be set when an event doesn't have a time.
    var datestamp: String?

    /// Controlled by drag-and-drop.
    /// No relation to the event's time.
    var sortDate: Date = Date.now

    var height: CGFloat = 0

    // MARK: Calendar Event
    init(ekEvent: EKEvent, sortDate: Date) {
        title = ekEvent.title
        time = ekEvent.startDate
        location = ekEvent.location()
        self.sortDate = sortDate

        // Note: This initializer automatically attaches the EKEventContext to the PlannerEvent
        _ = EKEventContext(ekEvent: ekEvent, plannerEvent: self)
    }

    // MARK: Routine Event
    init(
        routineEvent: RoutineEvent,
        startOfDay: DateInRegion,
        sortDate: Date
    ) {
        guard let routineEventContext = routineEvent.routineEventContext else {
            return
        }

        title = routineEventContext.title

        if let time = routineEventContext.date(on: startOfDay) {
            self.time = time
        } else {
            datestamp = startOfDay.datestamp
        }

        self.sortDate = sortDate

        // Note: This initializer automatically attaches the RoutineEventRecordContext to the PlannerEvent
        _ = RoutineEventRecordContext(
            routineEvent: routineEvent,
            plannerEvent: self
        )
    }

    // MARK: Untimed Event
    init(datestamp: String, sortDate: Date) {
        self.datestamp = datestamp
        self.sortDate = sortDate
    }
}
