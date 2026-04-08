//
//  RoutineBaseEvent.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import EventKit
import Foundation
import SwiftData

// Clean

@available(iOS 26.0, *)
@Model
class RecurringRoutineEvent {

    @Relationship(deleteRule: .nullify, inverse: \RoutineEvent.recurringParent)
    var events: [RoutineEvent] = []

    var title: String

    // Determines the event time of day.
    // Normalized to June 6, 2000.
    var time: Date?

    init(
        title: String = "",
        time: Date? = nil
    ) {
        self.time = time
        self.title = title
    }
}
