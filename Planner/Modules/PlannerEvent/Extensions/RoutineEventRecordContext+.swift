//
//  RoutineEventRecordContext+.swift
//  Planner
//
//  Created by Alex Green on 6/22/26.
//

import Foundation

extension RoutineEventRecordContext {
    var routineEventStableId: UUID? {
        routineEventContext?.stableId
    }
    
    var routineEventContext: RoutineEventContext? {
        routineEvent?.routineEventContext
    }
}
