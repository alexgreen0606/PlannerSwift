//
//  eventChips.swift
//  Planner
//
//  Created by Alex Green on 6/12/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func eventChips(
        on startOfDay: DateInRegion
    ) -> Predicate<PlannerEvent> {
        let startOfNextDay = (startOfDay + 1.days)
        
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date
        
        return #Predicate<PlannerEvent> { event in
            if let calendarEventContext = event.calendarContext {

                // MARK: Non-birthday calendar events that:

                return calendarEventContext.birthdayContactIdentifier == nil
                    && calendarEventContext.isAllDay

                    // MARK: Are all-day and exist on this day.

                    ? (calendarEventContext.startDate < plannerEnd
                        && calendarEventContext.endDate >= plannerStart)

                    // MARK: Are timed, exist on this day, and span outside of this day.

                    : (calendarEventContext.startDate < plannerStart
                        && calendarEventContext.endDate >= plannerStart
                        || calendarEventContext.endDate >= plannerEnd
                            && calendarEventContext.startDate < plannerEnd)
            } else {
                return false
            }
        }
    }
}
