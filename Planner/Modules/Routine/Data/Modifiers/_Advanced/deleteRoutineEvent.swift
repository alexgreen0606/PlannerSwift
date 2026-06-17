//
//  deleteRoutineEvent.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func deleteRoutineEvent(
        _ routineEvent: RoutineEvent,
        ekEventStore: EKEventStore,
        skipStaleCalendarRecordDeletion: Bool = false,
        skipSave: Bool = false,
    ) -> Set<String> {
        var staleCalendarItemExternalIdentifiers: Set<String> = []

        routineEvent.plannerEvents = prepareRoutineEventRecordsForDeletion(
            routineEvent.safePlannerEvents,
            staleCalendarItemExternalIdentifiers:
                &staleCalendarItemExternalIdentifiers,
            ekEventStore: ekEventStore
        )

        delete(routineEvent)

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
