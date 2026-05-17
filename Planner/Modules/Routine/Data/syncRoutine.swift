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

extension ModelContext {
    @MainActor
    func syncRoutine(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        weekday: Weekday,
        ekEventStore: EKEventStore,
        todaystamp: String
    ) {
        if planner.datestamp < todaystamp {
            // Never sync planners from the past. Their routine events will remain as-is.
            return
        }

        print("debug \(planner.datestamp) syncRoutine")

        if planner.safeExcludeRoutine {
            // Delete all routine variants when the routine is excluded from the planner.
            for variant in planner.safeRoutineEventVariants {
                delete(variant)
            }
            planner.routineEventVariants = []
        }

        // ------------------------------------------------------------------
        // MARK: Load in the day's existing routine events.

        // ------------------------------------------------------------------

        let routineEvents: [RoutineEvent] = loadSortedRoutineEvents(
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

        var finalPlannerEvents: [PlannerEvent] = []
        var eventsToMove: [PlannerEvent] = []

        for plannerEvent in storageEvents {
            if let routineEvent = plannerEvent.routineEvent {
                // MARK: Routine Event

                if planner.safeExcludeRoutine {
                    // Routines are excluded. Remove this record and continue.
                    deletePlannerEvent(
                        plannerEvent,
                        in: planner,
                        ekEventStore: ekEventStore
                    )
                    continue
                }

                guard
                    validatePlannerEventWeekday(
                        plannerEvent: plannerEvent,
                        routineEvent: routineEvent,
                        planner: planner,
                        ekEventStore: ekEventStore
                    )
                else {
                    continue
                }

                // Only consider the routine event as "existing" if this record originates from this planner.
                if plannerEvent.routineEventVariant == nil
                    || plannerEvent.routineEventVariant?.planner === planner
                {
                    existingRoutineEvents.removeValue(
                        forKey: routineEvent.stableId
                    )
                }

                if !plannerEvent.isRoutineVariant {
                    // Event is not a variant. Sync the event with the routine.
                    plannerEvent.syncWithRoutineEvent(
                        routineEvent,
                        on: plannerDay
                    )
                }

                if !routineEvent.syncedSortDatePlannerEventIds.contains(
                    plannerEvent.stableId
                ) {
                    // Skip events that need to be re-positioned in the list.
                    eventsToMove.append(plannerEvent)
                    continue
                }
            }

            // Track the events that still exist in the planner.
            finalPlannerEvents.append(plannerEvent)
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
                to: finalPlannerEvents,
                destinationComparatorId: { $0.routineEvent?.stableId }
            )

            plannerEvent.sortDate = generateSortDate(
                at: targetIndex,
                in: finalPlannerEvents,
                plannerDay: plannerDay
            )

            finalPlannerEvents.insert(plannerEvent, at: targetIndex)

            routineEvent.syncedSortDatePlannerEventIds.insert(
                plannerEvent.stableId
            )
        }

        // ------------------------------------------------------------------
        // MARK: Create New Routine Events.

        // ------------------------------------------------------------------

        if !planner.safeExcludeRoutine {
            let variantIds = Set(
                planner.routineEventVariants?.compactMap {
                    $0.routineEvent?.stableId
                } ?? []
            )

            let reverseSortedEvents: [RoutineEvent] =
                existingRoutineEvents.values
                    .sorted {
                        $0.sortDateMap[weekday]! > $1.sortDateMap[weekday]!
                    }

            for routineEvent in reverseSortedEvents
                where !variantIds.contains(routineEvent.stableId)
            {
                // Find a position for the event closest to its routine siblings.
                // Defaults to top of list otherwise.
                let targetIndex = generateTargetIndex(
                    near: routineEvent.stableId,
                    from: routineEvents,
                    to: finalPlannerEvents,
                    destinationComparatorId: { $0.routineEvent?.stableId }
                )

                let sortDate = generateSortDate(
                    at: targetIndex,
                    in: finalPlannerEvents,
                    plannerDay: plannerDay
                )

                let newEvent =
                    PlannerEvent(
                        datestamp: planner.datestamp,
                        sortDate: sortDate,
                        routineEvent: routineEvent,
                        plannerDay: plannerDay
                    )

                insert(newEvent)

                // Track the event at its position in the planner.
                finalPlannerEvents.insert(newEvent, at: targetIndex)
            }
        }
    }

    // MARK: - Helpers

    private func validatePlannerEventWeekday(
        plannerEvent: PlannerEvent,
        routineEvent: RoutineEvent,
        planner: Planner,
        ekEventStore: EKEventStore
    ) -> Bool {
        let sourceWeekday = {
            if let variantPlanner = plannerEvent.routineEventVariant?
                .planner
            {
                return Weekday.forDatestamp(variantPlanner.datestamp)
            }
            return Weekday.forDatestamp(planner.datestamp)
        }()

        if sourceWeekday == nil
            || !routineEvent.weekdays.contains(sourceWeekday!)
        {
            // This weekday was removed from the routine event. Remove this record and continue.
            deletePlannerEvent(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )

            return false
        }

        return true
    }
}
