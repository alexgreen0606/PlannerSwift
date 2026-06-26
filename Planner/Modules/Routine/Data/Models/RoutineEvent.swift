//
//  RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 5/19/26.
//

import Foundation
import SwiftData

@Model
class RoutineEvent {

    var routine: Routine?

    var routineEventContext: RoutineEventContext?

    var sortDate: Date = Date()

    var sortDateVersion: Double = 1.0

    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEventRecordContext.routineEvent
    )
    var routineEventRecordContexts: [RoutineEventRecordContext]?

    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEventVariant.routineEvent
    )
    var variants: [RoutineEventVariant]?

    init(
        routine: Routine,
        routineEventContext: RoutineEventContext,
        sortDate: Date
    ) {
        self.routine = routine
        self.routineEventContext = routineEventContext
        self.sortDate = sortDate

        routine.routineEvents.safeAppend(self)
        routineEventContext.routineEvents.safeAppend(self)
    }
}
