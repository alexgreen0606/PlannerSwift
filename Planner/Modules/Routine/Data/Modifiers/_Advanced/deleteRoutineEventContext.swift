//
//  deleteRoutineEventContext.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func deleteRoutineEventContext(
        _ routineEventContext: RoutineEventContext,
        ekEventStore: EKEventStore,
        skipStaleCalendarRecordDeletion: Bool = false,
        skipSave: Bool = false,
    ) -> Set<String> {
        var staleCalendarItemExternalIdentifiers: Set<String> = []
        
        for routineEvent in routineEventContext.safeRoutineEvents {
            routineEvent.plannerEvents = prepareRoutineEventRecordsForDeletion(
                routineEvent.safePlannerEvents,
                staleCalendarItemExternalIdentifiers:
                    &staleCalendarItemExternalIdentifiers,
                ekEventStore: ekEventStore
            )
        }

        delete(routineEventContext)

        if !skipStaleCalendarRecordDeletion {
            // Delete all planner events linked to the deleted calendar events.
            deleteCalendarRecords(
                calendarItemExternalIdentifiers:
                    staleCalendarItemExternalIdentifiers
            )
        }

        if !skipSave {
            safeSave("deleteRoutineEvent")
        }

        return staleCalendarItemExternalIdentifiers
    }
}
