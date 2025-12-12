//
//  PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Foundation
import SwiftData

@Model
class MultiDayConfig {
    var startEventId: String
    var endEventId: String
    
    init(startEventId: String, endEventId: String) {
        self.startEventId = startEventId
        self.endEventId = endEventId
    }
}

@Model
class CalendarConfig {
    var endIso: String
    var calendarEventId: String
    var calendarId: String
    var isAllDay: Bool
    var multiDayConfig: MultiDayConfig?

    init(endIso: String, calendarEventId: String, calendarId: String, isAllDay: Bool, multiDayConfig: MultiDayConfig? = nil
    ){
        self.endIso = endIso
        self.calendarEventId = calendarEventId
        self.calendarId = calendarId
        self.isAllDay = isAllDay
        self.multiDayConfig = multiDayConfig
    }
}

@Model
class TimeConfig {
    var startIso: String
    var calendarConfig: CalendarConfig?

    init(startIso: String, calendarConfig: CalendarConfig? = nil) {
        self.startIso = startIso
        self.calendarConfig = calendarConfig
    }
}

@available(iOS 26.0, *)
@Model
class PlannerEvent: ListItem {
    var datestamp: String
    var timeConfig: TimeConfig? = nil
    var recurringId: String? = nil
    
    init(datestamp: String, sortIndex: Double) {
        self.datestamp = datestamp
        super.init(sortIndex: sortIndex)
    }
}
