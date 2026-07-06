//
//  deleteRoutineEventContext.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func deleteRoutineEventContext(
        _ routineEventContext: RoutineEventContext,
        todayStartOfDay: DateInRegion,
        inLoop: Bool = false,
        ekEventStore: EKEventStore? = nil
    ) -> Set<String> {
        var externalCalendarIds: Set<String> = []

        for routineEvent in routineEventContext.safeRoutineEvents {
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
        }

        delete(routineEventContext)

        if !inLoop, let ekEventStore, !externalCalendarIds.isEmpty {
            // Delete stale calendar events and their records from today onward.
            deleteCalendarEvents(
                externalIds: externalCalendarIds,
                onOrAfter: todayStartOfDay,
                ekEventStore: ekEventStore
            )

            safeSave("deleteRoutineEventContext")
        }

        return externalCalendarIds
    }
}
