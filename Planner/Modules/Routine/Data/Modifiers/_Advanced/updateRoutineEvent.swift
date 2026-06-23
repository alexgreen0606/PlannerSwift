//
//  updateRoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func updateRoutineEvent(
        _ sourceRoutineEvent: RoutineEventContext?,
        with draftRoutineEvent: DraftRoutineEvent,
        sourceSortedRoutineEvents: [RoutineEventContext]?,
        plannerSyncService: PlannerSyncService,
        ekEventStore: EKEventStore
    ) {
        guard !draftRoutineEvent.weekdays.isEmpty else { return }

        let affectedWeekdays = Set(sourceRoutineEvent?.weekdays ?? []).union(
            draftRoutineEvent.weekdays
        )

        let routineEvent =
            sourceRoutineEvent
            ?? RoutineEventContext()

        routineEvent.syncWithDraftRoutineEvent(draftRoutineEvent)

        updateRoutineEventWeekdays(
            routineEvent,
            with: draftRoutineEvent.weekdays,
            sourceSortedRoutineEvents: sourceSortedRoutineEvents,
            ekEventStore: ekEventStore
        )

        insertIfNeeded(routineEvent)

        safeSave("updateRoutineEvent")

        // TODO: should I just update planner events directly? is this too wasteful/slow?
        plannerSyncService.invalidateRoutines(weekdays: affectedWeekdays)
    }
}
