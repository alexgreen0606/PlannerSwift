//
//  calendarRecords.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func calendarRecords(
        for calendarItemExternalIdentifiers: Set<String>
    ) -> Predicate<PlannerEvent> {
        return #Predicate<PlannerEvent> { event in
            if let eKEventContext = event.eKEventContext {
                return calendarItemExternalIdentifiers.contains(
                    eKEventContext.calendarItemExternalIdentifier
                )
            } else {
                return false
            }
        }
    }
    
    static func calendarRecords(
        on startOfDay: DateInRegion
    ) -> Predicate<PlannerEvent> {
        let startOfNextDay = (startOfDay + 1.days)
        
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date

        return #Predicate<PlannerEvent> { event in
            if let eKEventContext = event.eKEventContext {

                // MARK: Calendar events that exist on this day.

                return eKEventContext.startDate < plannerEnd
                    && eKEventContext.endDate > plannerStart

            } else {
                return false
            }
        }
    }
}
