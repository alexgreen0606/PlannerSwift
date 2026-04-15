//
//  syncRoutine.swift
//  Planner
//
//  Created by Alex Green on 4/15/26.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate

// Clean

extension ModelContext {

    @MainActor
    func syncRoutine(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        weekday: Weekday
    ) {

        print("debug \(planner.datestamp) syncRoutine")

        // ------------------------------------------------------------------
        // MARK: Load in the day's existing routine events.
        // ------------------------------------------------------------------

        let routineEvents: [RoutineEvent] = self.loadSortedRoutineEvents(
            for: weekday
        )

        var existingRoutineEvents = Dictionary(
            uniqueKeysWithValues: routineEvents.map { event in
                (event.stableId, event)
            }
        )

        // ------------------------------------------------------------------
        // MARK: Sync/Delete Existing Planner Events.
        // ------------------------------------------------------------------

        var validEvents: [PlannerEvent] = []
        var eventsToMove: [PlannerEvent] = []

        for plannerEvent in storageEvents {

            if let routineEvent = plannerEvent.routineEvent,
                let weekday = Weekday.from(planner.datestamp.weekday)
            {
                // MARK: Routine Event

                if !routineEvent.weekdays.contains(weekday) {
                    // This weekday was removed. Remove this record and continue.
                    // TODO: delete from calendar
                    self.delete(plannerEvent)
                    continue
                }

                if planner.finalExcludeRoutine {
                    // Routines are hidden. Remove this record and continue.
                    // TODO: delete from calendar
                    self.delete(plannerEvent)
                    continue
                }

                // TODO: dont sync if it's a calendar event
                // TODO: does calendar event mark this as an exception?

                existingRoutineEvents.removeValue(forKey: routineEvent.stableId)
                plannerEvent.syncWithRoutineEvent(routineEvent, on: plannerDay)

                if !routineEvent.syncedSortDatePlannerEventIds.contains(
                    plannerEvent.stableId
                ) {
                    // Skip events that need to be re-positioned in the list.
                    eventsToMove.append(plannerEvent)
                    continue
                }

            }

            // Track the events that still exist in the planner.
            validEvents.append(plannerEvent)
        }

        // ------------------------------------------------------------------
        // MARK: Re-position Moved Routine Events.
        // ------------------------------------------------------------------

        for plannerEvent in eventsToMove {
            guard let routineEvent = plannerEvent.routineEvent else {
                continue
            }

            // Find a position for the event closest to its routine siblings.
            let targetIndex = generateTargetIndex(
                near: routineEvent.stableId,
                from: routineEvents,
                to: validEvents,
                destinationComparatorId: { $0.routineEvent?.stableId }
            )

            plannerEvent.sortDate = generateSortDate(
                at: targetIndex,
                in: validEvents,
                plannerDay: plannerDay
            )

            validEvents.insert(plannerEvent, at: targetIndex)

            routineEvent.syncedSortDatePlannerEventIds.insert(
                plannerEvent.stableId
            )
        }

        // ------------------------------------------------------------------
        // MARK: Create New Routine Events.
        // ------------------------------------------------------------------

        if !planner.finalExcludeRoutine {

            let reverseSortedNewRoutineEvents: [RoutineEvent] =
                existingRoutineEvents.values
                .sorted {
                    $0.sortDateMap[weekday]! > $1.sortDateMap[weekday]!
                }

            for routineEvent in reverseSortedNewRoutineEvents {

                // Find a position for the event closest to its routine siblings.
                // Defaults to top of list otherwise.
                let targetIndex = generateTargetIndex(
                    near: routineEvent.stableId,
                    from: routineEvents,
                    to: validEvents,
                    destinationComparatorId: { $0.routineEvent?.stableId }
                )

                let sortDate = generateSortDate(
                    at: targetIndex,
                    in: validEvents,
                    plannerDay: plannerDay
                )

                let newEvent =
                    PlannerEvent(
                        date: plannerDay.date,
                        sortDate: sortDate,
                        routineEvent: routineEvent,
                        plannerDay: plannerDay
                    )

                self.insert(newEvent)

                // Track the event at its position in the planner.
                validEvents.insert(newEvent, at: targetIndex)
            }

        }

    }

}
