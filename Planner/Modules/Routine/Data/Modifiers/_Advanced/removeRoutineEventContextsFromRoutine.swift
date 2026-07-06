//
//  removeRoutineEventContextsFromRoutine.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func removeRoutineEventContextsFromRoutine(
        routineEventContexts: [RoutineEventContext],
        routine: Routine,
        todayStartOfDay: DateInRegion,
        ekEventStore: EKEventStore
    ) {
        var externalCalendarIds: Set<String> = []

        for routineEventContext in routineEventContexts {
            if routineEventContext.safeRoutineEvents.count < 2 {
                externalCalendarIds.formUnion(
                    deleteRoutineEventContext(
                        routineEventContext,
                        todayStartOfDay: todayStartOfDay,
                        inLoop: true,
                        ekEventStore: ekEventStore
                    )
                )
                continue
            }

            removeRoutineEventFromRoutine(
                routineEventContext: routineEventContext,
                weekdayRawValue: routine.weekdayRawValue,
                todayStartOfDay: todayStartOfDay,
                externalCalendarIds:
                    &externalCalendarIds
            )
        }

        // Delete stale calendar events and their records from today onward.
        if !externalCalendarIds.isEmpty {
            deleteCalendarEvents(
                externalIds: externalCalendarIds,
                onOrAfter: todayStartOfDay,
                ekEventStore: ekEventStore
            )
        }

        safeSave("removeRoutineEventContextsFromRoutine")
    }
}
