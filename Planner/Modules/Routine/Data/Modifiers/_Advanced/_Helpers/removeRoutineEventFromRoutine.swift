//
//  removeRoutineEventFromRoutine.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func removeRoutineEventFromRoutine(
        routineEventContext: RoutineEventContext,
        weekdayRawValue: String,
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

            delete(routineEvent)
        }
    }
}
