//
//  getPlannerEventTime.swift
//  Planner
//
//  Created by Alex Green on 12/3/25.
//

func getPlannerEventTime(event: PlannerEvent?) -> String? {
    guard let event = event else { return nil }
    guard let timeConfig = event.timeConfig else { return nil }
    
    // Special case: this is the end-record of a multiday event.
    if timeConfig.calendarConfig?.multiDayConfig?.endEventId == String(describing: event.id) {
        return timeConfig.calendarConfig?.endIso
    }
    
    return timeConfig.startIso
}
