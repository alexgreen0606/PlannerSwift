//
//  deletePlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func deletePlannerEvent(
        _ plannerEvent: PlannerEvent,
        /// Marks routine events as variants so they are not synced.
        in planner: Planner,
        /// Deletes calendar events, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil,
        skipSave: Bool = false
    ) {
        if let calendarItemExternalIdentifier = plannerEvent.eKEventContext?
            .calendarItemExternalIdentifier,
            let ekEventStore,
            !ekEventStore.attemptDeleteEvent(
                identifier: calendarItemExternalIdentifier
            )
        {
            return
        }

        if let routineEvent = plannerEvent.routineEvent,
            plannerEvent.routineEventVariant == nil,
            // Note: Variants should not be created when routine is excluded.
            !planner.safeExcludeRoutine
        {
            // Mark this routine event as a variant so it is not synced after deletion.
            insert(
                RoutineEventVariant(
                    routineEvent: routineEvent,
                    planner: planner
                )
            )
        }

        delete(plannerEvent)

        if !skipSave {
            safeSave("deletePlannerEvent")
        }
    }
}
