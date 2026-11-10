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

        // Note: iOS 27 no longer allows for "if let" on optional relationships.
        if #available(iOS 27, *) {
            return #Predicate<PlannerEvent> { event in
                if event.eKEventContext != nil {

                    // MARK: Timed calendar events that start on this day.

                    return event.eKEventContext!.isAllDay == false
                        && event.eKEventContext!.startDate >= plannerStart
                        && event.eKEventContext!.startDate < plannerEnd

                } else if let time = event.time {

                    // MARK: Timed planner events that exist on this day.

                    return time < plannerEnd && time >= plannerStart

                } else if let datestamp = event.datestamp {

                    // MARK: Untimed planner events that exist on this day.

                    return datestamp == plannerDatestamp

                } else {
                    return false
                }
            }
        } else {
            return #Predicate<PlannerEvent> { event in
                if let eKEventContext = event.eKEventContext {

                    // MARK: Timed calendar events that start on this day.

                    return !eKEventContext.isAllDay
                        && eKEventContext.startDate >= plannerStart
                        && eKEventContext.startDate < plannerEnd

                } else if let time = event.time {

                    // MARK: Timed planner events that exist on this day and
                    // either aren't flagged, or this is a planner from today or the future...

                    return time < plannerEnd && time >= plannerStart

                } else if let datestamp = event.datestamp {

                    // MARK: Untimed planner events that exist on this day and
                    // either aren't flagged, or this is a planner from today or the future...

                    return datestamp == plannerDatestamp

                } else {
                    return false
                }
            }
        }
    }
}
