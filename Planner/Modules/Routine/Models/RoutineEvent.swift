//
//  RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import Foundation
import SwiftData

@available(iOS 26.0, *)
@Model
class RoutineEvent: EventListItem {

    var time: Date?
    
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

    init() {
        super.init(sortDate: Date())
    }
}
