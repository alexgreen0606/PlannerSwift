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
        _ sourceRoutineEvent: RoutineEvent?,
        with draftRoutineEvent: DraftRoutineEvent,
        sourceSortedRoutineEvents: [RoutineEvent]?,
        ekEventStore: EKEventStore
    ) {
        guard !draftRoutineEvent.daysOfWeek.isEmpty else { return }

        let routineEvent =
            sourceRoutineEvent
            ?? RoutineEvent()

        routineEvent.syncWithDraftRoutineEvent(draftRoutineEvent)

        updateRoutineEventWeekdays(
            routineEvent,
            with: draftRoutineEvent.daysOfWeek,
            sourceSortedRoutineEvents: sourceSortedRoutineEvents,
            ekEventStore: ekEventStore
        )

        insertIfNeeded(routineEvent)

        safeSave("updateRoutineEvent")
    }
}
