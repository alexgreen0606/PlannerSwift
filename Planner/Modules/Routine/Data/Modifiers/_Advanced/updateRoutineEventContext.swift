//
//  updateRoutineEventContext.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func updateRoutineEventContext(
        _ sourceRoutineEventContext: RoutineEventContext?,
        with draftRoutineEvent: DraftRoutineEvent,
        sourceSortedRoutineEventContexts: [RoutineEventContext]?,
        plannerService: PlannerService,
        ekEventStore: EKEventStore
    ) {
        guard !draftRoutineEvent.weekdays.isEmpty else { return }

        let routineEventContext =
            sourceRoutineEventContext
            ?? RoutineEventContext()

        routineEventContext.syncWithDraftRoutineEvent(draftRoutineEvent)

        updateRoutineEventContextWeekdays(
            routineEventContext,
            with: draftRoutineEvent.weekdays,
            sourceSortedRoutineEventContexts: sourceSortedRoutineEventContexts,
            ekEventStore: ekEventStore
        )

        routineEventContext.version += 0.1

        insertIfNeeded(routineEventContext)

        safeSave("updateRoutineEventContext")

        plannerService.invalidateRoutines()

        if sourceRoutineEventContext == nil {
            plannerService.syncVisiblePlanners()
        }
    }
}
