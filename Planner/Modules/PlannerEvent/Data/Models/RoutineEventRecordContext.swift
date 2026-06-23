//
//  RoutineEventRecordContext.swift
//  Planner
//
//  Created by Alex Green on 6/21/26.
//

import SwiftData

@Model
class RoutineEventRecordContext {

    var plannerEvent: PlannerEvent?

    var routineEvent: RoutineEvent

    var routineEventVariant: RoutineEventVariant?

    var syncedVersion: Double = 1.0
    var syncedSortDateVersion: Double = 1.0

    init(routineEvent: RoutineEvent, plannerEvent: PlannerEvent) {
        self.plannerEvent = plannerEvent
        self.routineEvent = routineEvent

        syncedVersion = routineEvent.routineEventContext?.version ?? 1.0
        syncedSortDateVersion = routineEvent.sortDateVersion

        plannerEvent.routineEventRecordContext = self
        routineEvent.plannerEvents.safeAppend(plannerEvent)
    }
}
