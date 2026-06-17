//
//  generateRoutineEventSortDate.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func generateRoutineEventSortDate(
        at index: Int,
        /// May or may not contain the routine event being placed.
        in sortedRoutineEvents: [RoutineEvent],
        on weekday: Weekday
    ) -> Date {
        guard let baseDay = Self.baseRoutineDate else {
            // Fallback to now. This should never occur.
            return Date()
        }

        // TODO: should this just be a list of instances?
        return generateSortDate(
            at: index,
            in: sortedRoutineEvents,
            startOfDay: baseDay,
            getSortDate: {
                $0.instance(on: weekday)?.sortDate ?? baseDay.date
            },
            setSortDate: { event, sortDate in
                event.instance(on: weekday)?.sortDate = sortDate
            }
        )
    }
}
