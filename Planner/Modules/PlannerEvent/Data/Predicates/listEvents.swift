//
//  listEvents.swift
//  Planner
//
//  Created by Alex Green on 6/12/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func listEvents(
        on startOfDay: DateInRegion
    ) -> Predicate<PlannerEvent> {
        let startOfNextDay = (startOfDay + 1.days)
        
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date
        let plannerDatestamp = startOfDay.datestamp
        
        return #Predicate<PlannerEvent> { event in
            if let eKEventContext = event.eKEventContext {
                
                // MARK: Timed calendar events that start on this day.
                
                return !eKEventContext.isAllDay
                && eKEventContext.startDate >= plannerStart
                && eKEventContext.startDate < plannerEnd
                
            } else if let time = event.time {
                
                // MARK: Timed planner events that exist on this day.
                
                return time >= plannerStart && time < plannerEnd
                
            } else if let datestamp = event.datestamp {
                
                // MARK: Untimed planner events that exist on this day.
                
                return datestamp == plannerDatestamp
                
            } else {
                return false
            }
        }
    }
}
