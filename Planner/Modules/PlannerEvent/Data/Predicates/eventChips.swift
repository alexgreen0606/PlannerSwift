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
            if let eKEventContext = event.eKEventContext {

                // MARK: Non-birthday calendar events that:

                return eKEventContext.birthdayContactIdentifier == nil
                    && (eKEventContext.isAllDay

                        // MARK: Are all-day and exist on this day.

                        ? (eKEventContext.startDate < plannerEnd
                            && eKEventContext.endDate > plannerStart)

                        // MARK: Are timed, exist on this day, and span outside of this day.

                        : (eKEventContext.startDate < plannerStart
                            && eKEventContext.endDate > plannerStart
                            || eKEventContext.startDate < plannerEnd
                                && eKEventContext.endDate > plannerEnd))
            } else {
                return false
            }
        }
    }
}
