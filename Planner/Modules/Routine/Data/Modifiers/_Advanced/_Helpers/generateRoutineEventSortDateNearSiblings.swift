//
//  generateRoutineEventSortDateNearSiblings.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func generateRoutineEventSortDateNearSiblings(
        for routineEventContext: RoutineEventContext,
        /// The routine events from the routine where the event was selected.
        from sourceSortedRoutineEvents: [RoutineEvent] = [],
        routine: Routine
    ) -> Date {
        let destinationSortedRoutineEvents = getSortedRoutineEvents(
            for: routine
        )

        let targetIndex = generateRoutineEventIndex(
            near: routineEventContext.stableId,
            from: sourceSortedRoutineEvents,
            to: destinationSortedRoutineEvents
        )

        return safeGenerateRoutineEventSortDate(
            at: targetIndex,
            in: destinationSortedRoutineEvents,
            for: routine
        )
    }
}
