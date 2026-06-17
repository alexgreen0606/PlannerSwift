//
//  removeRoutineEventFromWeekday.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func removeRoutineEventFromWeekday(
        routineEvent: RoutineEvent,
        weekday: Weekday,
        staleCalendarItemExternalIdentifiers: inout Set<String>,
        ekEventStore: EKEventStore
    ) {
        for instance in routineEvent.safeWeekdayInstances
        where instance.weekdayRawValue == weekday.rawValue {
            
            instance.plannerEvents = prepareRoutineEventRecordsForDeletion(
                instance.safePlannerEvents,
                staleCalendarItemExternalIdentifiers:
                    &staleCalendarItemExternalIdentifiers,
                ekEventStore: ekEventStore
            )

            delete(instance)
        }
    }
}
