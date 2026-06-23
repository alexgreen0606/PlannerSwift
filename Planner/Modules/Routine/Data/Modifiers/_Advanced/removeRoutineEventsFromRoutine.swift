//
//  removeRoutineEventsFromRoutine.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func removeRoutineEventsFromRoutine(
        routineEventContexts: [RoutineEventContext],
        routine: Routine,
        ekEventStore: EKEventStore
    ) {
        var staleCalendarItemExternalIdentifiers: Set<String> = []

        for routineEventContext in routineEventContexts {
            if routineEventContext.safeRoutineEvents.count < 2 {
                staleCalendarItemExternalIdentifiers.formUnion(
                    deleteRoutineEventContext(
                        routineEventContext,
                        ekEventStore: ekEventStore,
                        skipStaleCalendarRecordDeletion: true,
                        skipSave: true
                    )
                )
                continue
            }

            removeRoutineEventFromRoutine(
                routineEventContext: routineEventContext,
                weekdayRawValue: routine.weekdayRawValue,
                staleCalendarItemExternalIdentifiers:
                    &staleCalendarItemExternalIdentifiers,
                ekEventStore: ekEventStore
            )
        }

        deleteCalendarRecords(
            calendarItemExternalIdentifiers:
                staleCalendarItemExternalIdentifiers
        )

        safeSave("removeRoutineEventsFromWeekday")
    }
}
