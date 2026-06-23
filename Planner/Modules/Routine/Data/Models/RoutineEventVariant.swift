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
    
    /// When this is nil, the event is hidden in the planner (due to manual deletion from user).
    @Relationship(deleteRule: .nullify, inverse: \PlannerEvent.routineEventRecordContext?.routineEventVariant)
    var plannerEvent: PlannerEvent?

    init(
        routineEvent: RoutineEvent,
        planner: Planner,
        plannerEvent: PlannerEvent? = nil
    ) {
        self.routineEvent = routineEvent
        self.planner = planner
        self.plannerEvent = plannerEvent
                
        routineEvent.variants.safeAppend(self)
        planner.routineEventVariants.safeAppend(self)
        plannerEvent?.routineEventRecordContext?.routineEventVariant = self
    }
}
