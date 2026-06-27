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
        for routineEvent: RoutineEventContext,
        /// The routine events from the routine where the event was selected.
        from sourceSortedRoutineEventContexts: [RoutineEventContext] = [],
        routine: Routine
    ) -> Date {
        let destinationSortedRoutineEventContexts = getSortedRoutineEventContexts(for: routine)

        let targetIndex = generateRoutineEventIndex(
            near: routineEvent.stableId,
            from: sourceSortedRoutineEventContexts,
            to: destinationSortedRoutineEventContexts
        )

        return generateRoutineEventSortDate(
            at: targetIndex,
            in: destinationSortedRoutineEventContexts,
            for: routine
        )
    }
}
