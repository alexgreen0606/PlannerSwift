//
//  RoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import Foundation
import SwiftData

// Clean

@available(iOS 26.0, *)
@Model
class RoutineEvent: EventListItem {
    
    var recurringParent: RecurringRoutineEvent?

    var dayOfWeek: DayOfWeek

    // The event is edited and diverges from its recurring parent.
    var isException: Bool = false

    // Stays in sync with the recurringParent unless isException is true.
    var time: Date?

    init(
        recurringParent: RecurringRoutineEvent? = nil,
        dayOfWeek: DayOfWeek,
        sortDate: Date
    ) {
        self.recurringParent = recurringParent
        self.dayOfWeek = dayOfWeek
        super.init(sortDate: sortDate)
    }
}
