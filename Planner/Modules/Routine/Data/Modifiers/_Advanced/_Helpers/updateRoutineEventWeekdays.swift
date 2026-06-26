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
    func updateRoutineEventContextWeekdays(
        _ routineEventContext: RoutineEventContext,
        with destinationWeekdays: Set<Weekday>,
        sourceSortedRoutineEvents: [RoutineEventContext]? = [],
        ekEventStore: EKEventStore
    ) {
        let sourceWeekdays = routineEventContext.weekdays

        // MARK: - Delete Planner, Routine, and Calendar Events From Weekdays That Have Been Removed

        var staleCalendarItemExternalIdentifiers: Set<String> = []

        let weekdaysToRemove = sourceWeekdays.subtracting(destinationWeekdays)
        for weekday in weekdaysToRemove {
            removeRoutineEventFromRoutine(
                routineEventContext: routineEventContext,
                weekdayRawValue: weekday.rawValue,
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

        let weekdaysToAdd = destinationWeekdays.subtracting(sourceWeekdays)

        let routines = getRoutines(for: weekdaysToAdd)
        for routine in routines {
            insert(
                RoutineEvent(
                    routine: routine,
                    routineEventContext: routineEventContext,
                    sortDate: generateSortDateNearSiblings(
                        for: routineEventContext,
                        from: sourceSortedRoutineEvents ?? [],
                        routine: routine
                    )
                )
            )
        }
    }

    // Note: Don't save the context.
    // This is only ever called as part of a larger pipeline.
}
