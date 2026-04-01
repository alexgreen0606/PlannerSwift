//
//  CalendarDayData.swift
//  Planner
//
//  Created by Alex Green on 3/12/26.
//

import EventKit

// Clean

struct CalendarDayData {
    let plannerChipEvents: [EKEvent]
    let birthdays: [Birthday]
    let occurrenceEvents: [String: EKEvent]
    let regularEvents: [String: EKEvent]
}
