//
//  CalendarSearchResults.swift
//  Planner
//
//  Created by Alex Green on 3/12/26.
//

import EventKit

// Clean

struct CalendarSearchResults {
    let plannerChipEvents: [EKEvent]
    let occurrenceEvents: [String: EKEvent]
    let regularEvents: [String: EKEvent]
}
