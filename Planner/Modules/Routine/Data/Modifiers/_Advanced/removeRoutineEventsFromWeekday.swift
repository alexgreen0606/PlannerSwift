//
//  removeRoutineEventsFromWeekday.swift
//  Planner
//
//  Created by Alex Green on 6/15/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func removeRoutineEventsFromWeekday(
        routineEvents: [RoutineEvent],
        weekday: Weekday,
        ekEventStore: EKEventStore
    ) {
        var staleCalendarItemExternalIdentifiers: Set<String> = []

        for routineEvent in routineEvents {
            if routineEvent.safeWeekdayInstances.count < 2 {
                staleCalendarItemExternalIdentifiers.formUnion(
                    deleteRoutineEvent(
                        routineEvent,
                        ekEventStore: ekEventStore,
                        skipStaleCalendarRecordDeletion: true,
                        skipSave: true
                    )
                )
                continue
            }

            removeRoutineEventFromWeekday(
                routineEvent: routineEvent,
                weekday: weekday,
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
