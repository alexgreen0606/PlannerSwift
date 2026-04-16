//
//  RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import Foundation
import SwiftData

// Clean

@available(iOS 26.0, *)
@Model
class RoutineEvent: EventListItem {

    // Event will appear in each day that exists as a key within this map.
    var sortDateMap: [Weekday: Date] = [:]

    var time: Date?

    @Relationship(deleteRule: .nullify, inverse: \PlannerEvent.routineEvent)
    var plannerEvents: [PlannerEvent]?

    // When an event's ID does not exist here, it will re-sync its sortDate with this event
    // and add itself to this set.
    var syncedSortDatePlannerEventIds: Set<UUID> = []

    init() {
        super.init(sortDate: Date())
    }
}
