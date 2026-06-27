//
//  removeRoutineEventContextsFromRoutine.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func removeRoutineEventContextsFromRoutine(
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
                        inLoop: true,
                        ekEventStore: ekEventStore
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

        safeSave("removeRoutineEventContextsFromRoutine")
    }
}
