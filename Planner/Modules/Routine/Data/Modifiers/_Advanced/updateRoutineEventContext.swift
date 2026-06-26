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
        plannerSyncService: PlannerSyncService,
        ekEventStore: EKEventStore
    ) {
        guard !draftRoutineEvent.weekdays.isEmpty else { return }

        let affectedWeekdays = Set(sourceRoutineEventContext?.weekdays ?? []).union(
            draftRoutineEvent.weekdays
        )

        let routineEventContext =
            sourceRoutineEventContext
            ?? RoutineEventContext()

        routineEventContext.syncWithDraftRoutineEvent(draftRoutineEvent)

        updateRoutineEventContextWeekdays(
            routineEventContext,
            with: draftRoutineEvent.weekdays,
            sourceSortedRoutineEvents: sourceSortedRoutineEventContexts,
            ekEventStore: ekEventStore
        )

        insertIfNeeded(routineEventContext)

        safeSave("updateRoutineEventContext")

        plannerSyncService.invalidateRoutines(weekdays: affectedWeekdays)
    }
}
