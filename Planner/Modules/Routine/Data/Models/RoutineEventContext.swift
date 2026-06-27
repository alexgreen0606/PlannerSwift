//
//  RoutineEventContext.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import Foundation
import SwiftData

@Model
class RoutineEventContext: EventDetails {

    var stableId: UUID = UUID()

    var title: String = ""
    var time: Date?

    var height: CGFloat = 0
    
    var version: Double = 1.0

    // MARK: Children
    @Relationship(
        deleteRule: .cascade,
        inverse: \RoutineEvent.routineEventContext
    )
    var routineEvents: [RoutineEvent]?

    init() {}
}
