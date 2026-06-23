//
//  RoutineEvent+.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

extension RoutineEvent {
    var safePlannerEvents: [PlannerEvent] {
        plannerEvents ?? []
    }
}
