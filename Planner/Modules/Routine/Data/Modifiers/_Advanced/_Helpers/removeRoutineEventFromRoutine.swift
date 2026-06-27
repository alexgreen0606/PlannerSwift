//
//  removeRoutineEventFromRoutine.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData

extension ModelContext {
    /// This will only ever be called if the routine event context has more than one weekday assigned.
    @MainActor
    func removeRoutineEventFromRoutine(
        routineEventContext: RoutineEventContext,
        weekdayRawValue: String,
        /// Collects EKEvent IDs that have been deleted from the calendar.
        staleCalendarItemExternalIdentifiers: inout Set<String>,
        ekEventStore: EKEventStore
    ) {
        for routineEvent in routineEventContext.safeRoutineEvents
        where routineEvent.routine?.weekdayRawValue == weekdayRawValue {
            for routineEventRecordContext in routineEvent
                .safeRoutineEventRecordContexts
            {
                guard let plannerEvent = routineEventRecordContext.plannerEvent
                else { continue }

                routineEventRecordContext.plannerEvent =
                    prepareRoutineEventRecordForDeletion(
                        plannerEvent,
                        staleCalendarItemExternalIdentifiers:
                            &staleCalendarItemExternalIdentifiers,
                        ekEventStore: ekEventStore
                    )
            }

            // This cascade-deletes planner events that remain in the relationship.
            delete(routineEvent)
        }
    }
}
