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

    // TODO: should I cascade delete these from the planner?
    @Relationship(deleteRule: .nullify, inverse: \Planner.routineEventVariants)
    var planner: Planner?

    @Relationship(deleteRule: .nullify, inverse: \PlannerEvent.routineEventVariant)
    var plannerEvent: PlannerEvent?

    init(
        routineEvent: RoutineEvent,
        planner: Planner,
        /// When this is nil, the event is hidden in the planner (due to manual deletion from user).
        plannerEvent: PlannerEvent? = nil
    ) {
        self.routineEvent = routineEvent
        self.planner = planner
        self.plannerEvent = plannerEvent
    }
}
