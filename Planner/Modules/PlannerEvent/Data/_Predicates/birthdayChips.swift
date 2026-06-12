//
//  birthdayChips.swift
//  Planner
//
//  Created by Alex Green on 6/12/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func birthdayChips(
        on startOfDay: DateInRegion
    ) -> Predicate<PlannerEvent> {
        let startOfNextDay = (startOfDay + 1.days)
        
        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date

        return #Predicate<PlannerEvent> { event in
            if let calendarContext = event.calendarContext {

                // MARK: Birthday calendar events that exist on this day.

                return calendarContext.birthdayContactIdentifier != nil
                    && calendarContext.startDate < plannerEnd
                    && calendarContext.endDate >= plannerStart

            } else {
                return false
            }
        }
    }
}
