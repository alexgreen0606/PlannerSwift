//
//  RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import Foundation
import SwiftData

@Model
class RoutineEvent: EventListItem {

    var stableId: UUID = UUID()

    var title: String = ""
    var time: Date?

    var isCompleted: Bool = false

    /// Controlled by drag-and-drop.
    /// No relation to the event's time.
    var sortDate: Date = Date.now

    var height: CGFloat = 0

    /// When a planner event's ID does not exist here, it will re-sync its sortDate with this event
    /// and add itself to this set.
    var syncedSortDatePlannerEventIds: Set<UUID> = []

    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEventWeekdayInstance.routineEvent
    )
    var weekdayInstances: [RoutineEventWeekdayInstance]?

    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEventVariant.routineEvent
    )
    var variants: [RoutineEventVariant]?

    @Relationship(deleteRule: .cascade, inverse: \PlannerEvent.routineEvent)
    var plannerEvents: [PlannerEvent]?

    init() {}
}
