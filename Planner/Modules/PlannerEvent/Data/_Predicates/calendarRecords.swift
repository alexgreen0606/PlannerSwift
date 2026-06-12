//
//  calendarRecords.swift
//  Planner
//
//  Created by Alex Green on 6/12/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func calendarRecords(
        on startOfDay: DateInRegion
    ) -> Predicate<PlannerEvent> {
        let startOfNextDay = (startOfDay + 1.days)
        
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date

        return #Predicate<PlannerEvent> { event in
            if let calendarContext = event.calendarContext {

                // MARK: Calendar events that exist on this day.

                return calendarContext.startDate < plannerEnd
                    && calendarContext.endDate > plannerStart

            } else {
                return false
            }
        }
    }
}
