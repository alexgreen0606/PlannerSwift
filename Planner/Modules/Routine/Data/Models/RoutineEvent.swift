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

    var sortDate: Date = Date()

    var sortDateVersion: Double = 1.0

    // MARK: Parent
    var routineEventContext: RoutineEventContext?

    // MARK: Sibling
    var routine: Routine?

    // MARK: Children
    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEventRecordContext.routineEvent
    )
    var routineEventRecordContexts: [RoutineEventRecordContext]?

    init(
        routine: Routine,
        routineEventContext: RoutineEventContext,
        sortDate: Date
    ) {
        self.sortDate = sortDate

        self.routineEventContext = routineEventContext
        routineEventContext.routineEvents.safeAppend(self)

        self.routine = routine
        routine.routineEvents.safeAppend(self)
    }
}
