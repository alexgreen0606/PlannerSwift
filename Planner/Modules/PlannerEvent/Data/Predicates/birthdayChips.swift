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
            if let eKEventContext = event.eKEventContext {

                // MARK: Birthday calendar events that exist on this day.

                return eKEventContext.birthdayContactIdentifier != nil
                    && eKEventContext.startDate < plannerEnd
                    && eKEventContext.endDate >= plannerStart

            } else {
                return false
            }
        }
    }
}
