//
//  updateRoutineEventWeekdays.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func updateRoutineEventWeekdays(
        _ routineEvent: RoutineEvent,
        with destinationWeekdays: Set<Weekday>,
        sourceSortedRoutineEvents: [RoutineEvent]? = [],
        ekEventStore: EKEventStore
    ) {
        let sourceWeekdays = routineEvent.weekdays

        // MARK: - Delete Planner, Routine, and Calendar Events From Weekdays That Have Been Removed

        var staleCalendarItemExternalIdentifiers: Set<String> = []

        let weekdaysToRemove = sourceWeekdays.subtracting(destinationWeekdays)
        for weekday in weekdaysToRemove {
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

        // MARK: - Create Instances For Weekdays That Have Been Added

        // MARK: Place new events near their siblings.
        let weekdaysToAdd = destinationWeekdays.subtracting(sourceWeekdays)
        for weekday in weekdaysToAdd {
            let instance = RoutineEventWeekdayInstance(
                weekday: weekday,
                sortDate: generateSortDateNearSiblings(
                    for: routineEvent,
                    on: weekday,
                    from: sourceSortedRoutineEvents ?? []
                )
            )

            instance.routineEvent = routineEvent
            routineEvent.weekdayInstances?.append(instance)
            
            insert(instance)
        }
    }

    // Note: Don't save the context.
    // This is only ever called as part of a larger pipeline.
}
