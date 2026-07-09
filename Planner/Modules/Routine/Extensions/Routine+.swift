//
//  Routine+.swift
//  Planner
//
//  Created by Alex Green on 7/8/26.
//

extension Routine {
    var safeRoutineEvents: [RoutineEvent] {
        routineEvents ?? []
    }
    
    var safePlanners: [Planner] {
        planners ?? []
    }
}
