//
//  removeRoutineEventFromRoutine.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    /// This will only ever be called if the routine event context has more than one weekday assigned.
    @MainActor
    func removeRoutineEventFromRoutine(
        routineEventContext: RoutineEventContext,
        weekdayRawValue: String,
        todayStartOfDay: DateInRegion,
        /// Collects calendar event external IDs that must be deleted from the calendar.
        externalCalendarIds: inout Set<String>
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
                        cutoffDay: todayStartOfDay,
                        externalCalendarIds: &externalCalendarIds
                    )
            }

            // This cascade-deletes planner events that remain in the relationship.
            delete(routineEvent)
        }
    }
}
