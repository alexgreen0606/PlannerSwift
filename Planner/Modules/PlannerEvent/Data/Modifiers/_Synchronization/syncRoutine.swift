//
//  syncRoutine.swift
//  Planner
//
//  Created by Alex Green on 4/15/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func syncRoutine(
        for planner: Planner,
        startOfDay: DateInRegion,
        weekday: Weekday,
        todaystamp: String,
        ekEventStore: EKEventStore
    ) {
        // MARK: - Skip Synchronization Of Past Planners

        if planner.datestamp < todaystamp {
            // Past routine events will never change.
            return
        }

        // MARK: - Delete All Variants If Routine Is Excluded

        if planner.safeExcludeRoutine {
            for variant in planner.safeRoutineEventVariants {
                delete(variant)
            }
            planner.routineEventVariants?.removeAll()
        }

        // MARK: - Load In Routine For This Weekday

        let routineEvents: [RoutineEvent] = getSortedRoutineEvents(
            for: weekday
        )

        var existingRoutineEvents = Dictionary(
            uniqueKeysWithValues: routineEvents.map { event in
                (event.stableId, event)
            }
        )

        // MARK: - Sync/Delete Existing Planner Events

        var eventsToMove: [PlannerEvent] = []
        var sortedListEvents: [PlannerEvent]?

        let plannerEvents = getPlannerEvents(on: startOfDay)

        for plannerEvent in plannerEvents {
            guard let routineEvent = plannerEvent.routineEvent else {
                continue
            }

            guard
                validateRoutineEventSynchronization(
                    plannerEvent: plannerEvent,
                    routineEvent: routineEvent,
                    planner: planner,
                    ekEventStore: ekEventStore
                )
            else {
                continue
            }

            // Mark the routine event as existing if this event originated in this planner.

            let originatesFromPlanner =
                plannerEvent.routineEventVariant?.planner == nil
                || plannerEvent.routineEventVariant?.planner === planner

            if originatesFromPlanner {
                existingRoutineEvents.removeValue(
                    forKey: routineEvent.stableId
                )
            }

            // Sync with routine event if this is not a variant.
            if !plannerEvent.isRoutineVariant {
                plannerEvent.syncWithRoutineEvent(
                    routineEvent,
                    on: startOfDay
                )
            }

            // Invalidate planner event position if it has not updated its position since the routine event position was changed.
            if !routineEvent.syncedSortDatePlannerEventIds.contains(
                plannerEvent.stableId
            ) {
                eventsToMove.append(plannerEvent)
                continue
            }
        }

        // MARK: - Re-position Moved Routine Events

        if !eventsToMove.isEmpty {

            sortedListEvents = getSortedListEvents(on: startOfDay)

            for plannerEvent in eventsToMove {
                guard let routineEvent = plannerEvent.routineEvent else {
                    continue
                }

                // Find a position for the event closest to its routine siblings.

                let targetIndex = generateRoutineEventIndex(
                    near: routineEvent.stableId,
                    from: routineEvents,
                    to: sortedListEvents!,
                    destinationComparatorId: { $0.routineEvent?.stableId }
                )

                plannerEvent.sortDate = generateSortDate(
                    at: targetIndex,
                    in: sortedListEvents!,
                    startOfDay: startOfDay
                )

                // Mark the planner event's position as valid.
                routineEvent.syncedSortDatePlannerEventIds.insert(
                    plannerEvent.stableId
                )

                // Track the event at its new position in the planner.
                sortedListEvents!.insert(plannerEvent, at: targetIndex)
            }
        }

        // MARK: - Create New Routine Events

        guard !planner.safeExcludeRoutine, !existingRoutineEvents.isEmpty else {
            return
        }

        // Track variant routine events. These will not be added.
        let plannerVariantIds = Set(
            planner.safeRoutineEventVariants.compactMap {
                $0.routineEvent?.stableId
            }
        )

        let reverseSortedEvents: [RoutineEvent] = existingRoutineEvents
            .values.sorted {
                guard
                    let firstSortDate = $0.instance(on: weekday)?.sortDate,
                    let secondSortDate = $1.instance(on: weekday)?.sortDate
                else {
                    return false
                }

                return firstSortDate > secondSortDate
            }

        sortedListEvents =
            sortedListEvents ?? getSortedListEvents(on: startOfDay)

        for routineEvent in reverseSortedEvents
        where !plannerVariantIds.contains(routineEvent.stableId) {
            // Find a position for the event closest to its routine siblings.
            // Defaults to top of list otherwise.
            let targetIndex = generateRoutineEventIndex(
                near: routineEvent.stableId,
                from: routineEvents,
                to: sortedListEvents!,
                destinationComparatorId: { $0.routineEvent?.stableId }
            )

            let sortDate = generateSortDate(
                at: targetIndex,
                in: sortedListEvents!,
                startOfDay: startOfDay
            )
            
            // TODO: do I add the event to the routine event planner events as well? And
            // also add it to the weekday instance?

            let newEvent =
                PlannerEvent(
                    routineEvent: routineEvent,
                    startOfDay: startOfDay,
                    sortDate: sortDate,
                )

            insert(newEvent)

            // Track the event at its position in the planner.
            sortedListEvents!.insert(newEvent, at: targetIndex)
        }
    }

    // MARK: - Helpers

    private func validateRoutineEventSynchronization(
        plannerEvent: PlannerEvent,
        routineEvent: RoutineEvent,
        planner: Planner,
        ekEventStore: EKEventStore
    ) -> Bool {
        // MARK: Delete event if routines are excluded.

        if planner.safeExcludeRoutine {
            deletePlannerEvent(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        // Note: This is the weekday that the event originates from. May not match the planner's weekday.
        // For example, Tuesday's occurrence gets transferred to Wednesday.
        // In this case, Tuesday still "owns" the event. Removing the event from Tuesdays will still
        // cause the occurrence to be deleted from Wednesday.
        let sourceWeekday = {
            if let variantPlanner = plannerEvent.routineEventVariant?
                .planner
            {
                return Weekday.forDatestamp(variantPlanner.datestamp)
            }
            return Weekday.forDatestamp(planner.datestamp)
        }()

        // MARK: Delete event if its origin weekday has been removed from the routine event.

        guard let sourceWeekday,
            routineEvent.instance(on: sourceWeekday) != nil
        else {
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
