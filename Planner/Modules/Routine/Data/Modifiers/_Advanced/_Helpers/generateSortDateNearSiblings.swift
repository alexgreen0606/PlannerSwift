//
//  generateSortDateNearSiblings.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func generateSortDateNearSiblings(
        for routineEvent: RoutineEvent,
        on weekday: Weekday,
        /// The routine events from the routine where the event was selected.
        from sourceSortedEvents: [RoutineEvent] = []
    ) -> Date {
        let destinationSortedEvents = getSortedRoutineEvents(for: weekday)

        let targetIndex = generateRoutineEventIndex(
            near: routineEvent.stableId,
            from: sourceSortedEvents,
            to: destinationSortedEvents
        )

        return generateRoutineEventSortDate(
            at: targetIndex,
            in: destinationSortedEvents,
            on: weekday
        )
    }
}
