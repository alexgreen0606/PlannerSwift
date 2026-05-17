//
//  CalendarDayData.swift
//  Planner
//
//  Created by Alex Green on 3/12/26.
//

import EventKit

struct CalendarDayData {
    var plannerChipEvents: [EKEvent] = []
    var birthdays: [Birthday] = []
    var occurrenceEvents: [String: EKEvent] = [:]
    var regularEvents: [String: EKEvent] = [:]
}
