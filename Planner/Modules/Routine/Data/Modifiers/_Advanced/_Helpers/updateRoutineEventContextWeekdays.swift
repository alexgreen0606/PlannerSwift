//
//  updateRoutineEventContextWeekdays.swift
//  Planner
//
//  Created by Alex Green on 6/16/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func updateRoutineEventContextWeekdays(
        _ routineEventContext: RoutineEventContext,
        with destinationWeekdays: Set<Weekday>,
        sourceSortedRoutineEventContexts: [RoutineEventContext]? = [],
        todayStartOfDay: DateInRegion,
        ekEventStore: EKEventStore
    ) {
        let sourceWeekdays = routineEventContext.weekdays

        // MARK: - Delete Planner, Routine, and Calendar Events From Weekdays That Have Been Removed

        var externalCalendarIds: Set<String> = []

        let weekdaysToRemove = sourceWeekdays.subtracting(destinationWeekdays)
        for weekday in weekdaysToRemove {
            removeRoutineEventFromRoutine(
                routineEventContext: routineEventContext,
                weekdayRawValue: weekday.rawValue,
                todayStartOfDay: todayStartOfDay,
                externalCalendarIds:
                    &externalCalendarIds
            )
        }

        // Delete stale calendar events and their records from today onward.
        if !externalCalendarIds.isEmpty {
            deleteCalendarEvents(
                externalIds: externalCalendarIds,
                onOrAfter: todayStartOfDay,
                ekEventStore: ekEventStore
            )
        }

        // MARK: - Create Instances For Weekdays That Have Been Added

        let weekdaysToAdd = destinationWeekdays.subtracting(sourceWeekdays)

        let routines = getRoutines(for: weekdaysToAdd)
        for routine in routines {
            let sortDate = generateRoutineEventSortDateNearSiblings(
                for: routineEventContext,
                from: sourceSortedRoutineEventContexts ?? [],
                routine: routine
            )

            insert(
                RoutineEvent(
                    routine: routine,
                    routineEventContext: routineEventContext,
                    sortDate: sortDate
                )
            )
        }
    }

    // Note: Don't save the context.
    // This is only ever called as part of a larger pipeline.
}
