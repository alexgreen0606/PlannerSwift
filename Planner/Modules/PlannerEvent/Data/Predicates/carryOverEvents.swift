//
//  carryOverEvents.swift
//  Planner
//
//  Created by Alex Green on 11/9/26.
//

import SwiftDate
import SwiftUI

extension PlannerEvent {
    static func carryOverEvents(todayStartOfDay: DateInRegion) -> Predicate<
        PlannerEvent
    > {
        let todaystamp = todayStartOfDay.datestamp

        return #Predicate<PlannerEvent> { event in
            if !event.isFlagged || event.eKEventContext != nil
                || event.isCompleted
            {

                // MARK: Ignore unflagged events, calendar events, and completed events.

                return false

            } else if let time = event.time {

                // MARK: Timed, flagged planner events before today.

                return time < todayStartOfDay.date

            } else if let datestamp = event.datestamp {

                // MARK: Untimed, flagged planner events before today.

                return datestamp < todaystamp

            } else {
                return false
            }
        }
    }
}
