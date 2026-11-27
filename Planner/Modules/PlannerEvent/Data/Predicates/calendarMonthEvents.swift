//
//  calendarMonthEvents.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import SwiftUI

extension PlannerEvent {
    /// Planner-owned events that may land within a calendar month grid.
    /// Note: Events are bucketed into each day's 24-hour window afterwards.
    static func calendarMonthEvents(
        start: Date,
        end: Date,
        minDatestamp: String,
        maxDatestamp: String
    ) -> Predicate<PlannerEvent> {
        #Predicate<PlannerEvent> { event in
            if event.eKEventContext != nil {

                // MARK: Legacy calendar-backed events. Skip.

                return false

            } else if let time = event.time {
                return time >= start && time < end

            } else if let datestamp = event.datestamp {
                return datestamp >= minDatestamp && datestamp <= maxDatestamp

            } else {
                return false
            }
        }
    }
}
