//
//  RoutineEventRecordContext.swift
//  Planner
//
//  Created by Alex Green on 6/21/26.
//

import SwiftData

@Model
class RoutineEventRecordContext {

    var syncedVersion: Double = 1.0
    var syncedSortDateVersion: Double = 1.0
    
    var isVariant: Bool = false

    // MARK: Parent
    var routineEvent: RoutineEvent?

    // MARK: Parent
    /// Planners are deleted when they are far in the past. This record has no point of existing at that point.
    var planner: Planner?

    // MARK: Child
    /// When this is nil, the routine event has been manually deleted within the planner.
    @Relationship(
        deleteRule: .cascade,
        inverse: \PlannerEvent.routineEventRecordContext
    )
    var plannerEvent: PlannerEvent?

    init(
        routineEvent: RoutineEvent,
        planner: Planner,
        plannerEvent: PlannerEvent
    ) {
        syncedVersion = routineEvent.routineEventContext?.version ?? 1.0
        syncedSortDateVersion = routineEvent.sortDateVersion

        self.routineEvent = routineEvent
        routineEvent.routineEventRecordContexts.safeAppend(self)

        self.planner = planner
        planner.routineEventRecordContexts.safeAppend(self)

        self.plannerEvent = plannerEvent
        plannerEvent.routineEventRecordContext = self
    }
}
