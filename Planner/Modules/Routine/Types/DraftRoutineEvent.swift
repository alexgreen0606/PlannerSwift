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

    init(routineEvent: RoutineEvent) {
        self.title = routineEvent.title
        self.date = routineEvent.time ?? Self.defaultDate()
        self.hasTime = routineEvent.time != nil
        self.weekdays = routineEvent.weekdays
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
