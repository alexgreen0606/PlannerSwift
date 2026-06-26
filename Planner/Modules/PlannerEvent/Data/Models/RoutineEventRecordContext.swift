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
    
    // MARK: Parent
    var routineEvent: RoutineEvent?
    
    // MARK: Sibling
    @Relationship(deleteRule: .cascade)
    var plannerEvent: PlannerEvent?

    // TODO: I think I should directly store the planner here, then RoutineEventVariant isn't needed. This becomes the record.

    // MARK: Sibling (no deletion)
    var variant: RoutineEventVariant?

    init(routineEvent: RoutineEvent, plannerEvent: PlannerEvent) {
        syncedVersion = routineEvent.routineEventContext?.version ?? 1.0
        syncedSortDateVersion = routineEvent.sortDateVersion
        
        self.routineEvent = routineEvent
        routineEvent.routineEventRecordContexts.safeAppend(self)
        
        self.plannerEvent = plannerEvent
        plannerEvent.routineEventRecordContext = self
    }
}
