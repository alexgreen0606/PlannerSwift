//
//  RoutineEventVariant.swift
//  Planner
//
//  Created by Alex Green on 4/19/26.
//

import SwiftData

@Model
class RoutineEventVariant {
    
    var routineEvent: RoutineEvent?
    
    var planner: Planner?
    
    // MARK: Sibling (no deletion)
    /// When this is nil, the event is hidden in the planner (due to manual deletion from user).
    @Relationship(
        deleteRule: .nullify,
        inverse: \RoutineEventRecordContext.variant
    )
    var routineEventRecordContext: RoutineEventRecordContext?

    init(
        routineEvent: RoutineEvent,
        planner: Planner,
        plannerEvent: PlannerEvent? = nil
    ) {
        self.routineEvent = routineEvent
        self.planner = planner
        self.routineEventRecordContext = plannerEvent?.routineEventRecordContext
                
        routineEvent.variants.safeAppend(self)
        planner.routineEventVariants.safeAppend(self)
        plannerEvent?.routineEventRecordContext?.variant = self
    }
}
