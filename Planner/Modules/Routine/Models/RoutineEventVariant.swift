//
//  RoutineEventVariant.swift
//  Planner
//
//  Created by Alex Green on 4/19/26.
//

import EventKit
import Foundation
import SwiftData

@Model
class RoutineEventVariant {
    
    var routineEvent: RoutineEvent?
    
    var calendarItemExternalIdentifier: String?

    @Relationship(deleteRule: .nullify, inverse: \Planner.routineEventVariants)
    var planner: Planner?

    @Relationship(deleteRule: .nullify, inverse: \PlannerEvent.routineEventVariant)
    var plannerEvent: PlannerEvent?

    init(
        routineEvent: RoutineEvent,
        planner: Planner,

        // When neither of these exists, the event is hidden in the planner.
        plannerEvent: PlannerEvent? = nil,
        calendarItemExternalIdentifier: String? = nil
    ) {
        self.routineEvent = routineEvent
        self.planner = planner
        self.plannerEvent = plannerEvent
        self.calendarItemExternalIdentifier = calendarItemExternalIdentifier
    }
}
