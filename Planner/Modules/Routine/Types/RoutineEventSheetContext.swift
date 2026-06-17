//
//  RoutineEventSheetContext.swift
//  Planner
//
//  Created by Alex Green on 5/15/26.
//

import Foundation

struct RoutineEventSheetContext: Identifiable {
    var routineEvent: RoutineEvent

    var id: String {
        routineEvent.transitionId
    }
}
