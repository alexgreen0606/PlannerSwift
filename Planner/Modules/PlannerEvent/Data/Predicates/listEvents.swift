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
        on startOfDay: DateInRegion,
        todaystamp: String
    ) -> Predicate<PlannerEvent> {
        let startOfNextDay = (startOfDay + 1.days)

        let plannerStart = startOfDay.date
        let plannerEnd = startOfNextDay.date
        let plannerDatestamp = startOfDay.datestamp

        let isTodayPlanner = startOfDay.datestamp == todaystamp

        return #Predicate<PlannerEvent> { event in
            if event.eKEventContext != nil {

                // MARK: Timed calendar events that start on this day.

                return event.eKEventContext!.isAllDay == false
                    && event.eKEventContext!.startDate >= plannerStart
                    && event.eKEventContext!.startDate < plannerEnd

            } else if let time = event.time {

                // MARK: Timed planner events that exist on this day,

                return time < plannerEnd
                    && (time >= plannerStart

                        // or the event exists before this day, the event is flagged,
                        // and either the event is pending and this is today's planner,
                        // or the event was completed in this planner.

                        || (event.isFlagged
                            && ((!event.isCompleted && isTodayPlanner)
                                || event.completedOn == plannerDatestamp)))

            } else if let datestamp = event.datestamp {

                // MARK: Untimed planner events that exist on this day,

                return datestamp == plannerDatestamp

                    // or the event exists before this day, the event is flagged,
                    // and either the event is pending and this is today's planner,
                    // or the event was completed in this planner.

                    || (datestamp < plannerDatestamp
                        && event.isFlagged
                        && ((!event.isCompleted && isTodayPlanner)
                            || event.completedOn == plannerDatestamp))

            } else {
                return false
            }
        }
    }
}
