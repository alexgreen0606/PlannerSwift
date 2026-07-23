//
//  DraftRoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 6/18/26.
//

import Foundation
import SwiftDate

struct DraftRoutineEvent {
    var title: String = ""
    var date: Date
    var hasTime: Bool = false
    var weekdays: Set<Weekday> = []

    init() {
        self.date = Self.defaultDate()
    }

    init(routineEventContext: RoutineEventContext) {
        self.title = routineEventContext.title
        self.date = routineEventContext.time ?? Self.defaultDate()
        self.hasTime = routineEventContext.time != nil
        self.weekdays = routineEventContext.weekdays
    }

    // MARK: - Helper Function

    static func defaultDate() -> Date {
        let hour = DateInRegion(Date(), region: .local).hour

        // Default time to now, rounded down to the start of the hour.
        return DateInRegion(
            year: 2000,
            month: 6,
            day: 6,
            hour: hour,
            minute: 0,
            second: 0,
            region: Region.UTC
        ).date
    }
}
