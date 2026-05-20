//
//  RoutineEventWeekdayInstance.swift
//  Planner
//
//  Created by Alex Green on 5/19/26.
//

import EventKit
import Foundation
import SwiftData

@Model
class RoutineEventWeekdayInstance {

    /// Note: This is required by SwiftData limitations. Query by enums is currently not supported.
    var weekdayRawValue: String = ""

    var sortDate: Date = Date()

    var routineEvent: RoutineEvent?

    init(weekday: Weekday, sortDate: Date) {
        self.weekdayRawValue = weekday.rawValue
        self.sortDate = sortDate
    }
}
