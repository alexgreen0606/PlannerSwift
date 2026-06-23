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
        todaystamp: String,
        ekEventStore: EKEventStore
    ) {
        guard let routine = planner.routine else {
            return
        }

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

        let routineEventContexts: [RoutineEventContext] =
            getSortedRoutineEvents(
                for: routine
            )

        var existingRoutineEvents = Dictionary(
            uniqueKeysWithValues: routineEventContexts.map { event in
                (event.stableId, event)
            }
        )

        // MARK: - Sync Existing Planner Events

        var plannerEventsToPosition: [PlannerEvent] = []
        var sortedListEvents: [PlannerEvent]?

        let plannerEvents = getPlannerEvents(on: startOfDay)

        for plannerEvent in plannerEvents {
            guard
                let routineEventRecordContext = plannerEvent
                    .routineEventRecordContext,
                let routineEventContext = plannerEvent.routineEventContext
            else {
                continue
            }

            let routineEvent = routineEventRecordContext.routineEvent

            // Invalidate planner event position if it has not updated its position since the routine event position was changed.
            if routineEventRecordContext.syncedSortDateVersion
                != routineEvent.sortDateVersion
            {
                plannerEventsToPosition.append(plannerEvent)
            }

            guard
                routineEventRecordContext.syncedVersion
                    != routineEventContext.version
            else {
                continue
            }

            guard
                validateRoutineEventSynchronization(
                    plannerEvent: plannerEvent,
                    routineEvent: routineEventContext,
                    planner: planner,
                    ekEventStore: ekEventStore
                )
            else {
                continue
            }

            // Mark the routine event as existing if this event originated in this planner.

            let originatesFromPlanner =
                routineEventRecordContext.routineEventVariant?.planner == nil
                || routineEventRecordContext.routineEventVariant?.planner
                    === planner

            if originatesFromPlanner {
                existingRoutineEvents.removeValue(
                    forKey: routineEventContext.stableId
                )
            }

            // Sync with routine event if this is not a variant.
            if !plannerEvent.isRoutineVariant {
                plannerEvent.syncWithRoutineEvent(
                    routineEvent,
                    on: startOfDay
                )
            }
        }

        // MARK: - Re-position Moved Routine Events

        if !plannerEventsToPosition.isEmpty {

            sortedListEvents = getSortedListEvents(on: startOfDay)

            for plannerEvent in plannerEventsToPosition {

                // TODO: what if the event isnt from this weekday initially?
                // Do I load in the events for that weekday?

                guard
                    let routineEventRecordContext = plannerEvent
                        .routineEventRecordContext,
                    let routineEventContext = routineEventRecordContext
                        .routineEvent.routineEventContext,
                    let safeSortedListEvents = sortedListEvents
                else {
                    continue
                }

                // Find a position for the event closest to its routine siblings.

                let targetIndex = generateRoutineEventIndex(
                    near: routineEventContext.stableId,
                    from: routineEventContexts,
                    to: safeSortedListEvents,
                    destinationComparatorId: {
                        $0.routineEventRecordContext?.routineEventStableId
                    }
                )

                plannerEvent.sortDate = generateSortDate(
                    at: targetIndex,
                    in: safeSortedListEvents,
                    startOfDay: startOfDay
                )

                // Sync the planner event's sort date version.
                plannerEvent.routineEventRecordContext?.syncedSortDateVersion =
                    routineEventRecordContext.routineEvent.sortDateVersion

                // Track the event at its new position in the planner.
                sortedListEvents?.insert(plannerEvent, at: targetIndex)
            }
        }

        // MARK: - Create New Routine Events

        guard !planner.safeExcludeRoutine, !existingRoutineEvents.isEmpty else {
            return
        }

        // Track variant routine events. These will not be added.
        let plannerVariantIds = Set(
            planner.safeRoutineEventVariants.compactMap {
                $0.routineEvent?.routineEventContext?.stableId
            }
        )

        let reverseSortedRoutineEventContexts: [RoutineEventContext] =
            existingRoutineEvents
            .values
            .filter {
                !plannerVariantIds.contains($0.stableId)
            }
            .sorted {
                guard
                    let firstSortDate = $0.routineEvent(for: routine)?.sortDate,
                    let secondSortDate = $1.routineEvent(for: routine)?.sortDate
                else {
                    return false
                }

                return firstSortDate > secondSortDate
            }

        sortedListEvents =
            sortedListEvents ?? getSortedListEvents(on: startOfDay)

        for routineEventContext in reverseSortedRoutineEventContexts {
            guard
                let routineEvent = routineEventContext.routineEvent(
                    for: routine
                )
            else {
                continue
            }

            // Find a position for the routine event record closest to its routine siblings.
            // Defaults to top of list otherwise.
            let targetIndex = generateRoutineEventIndex(
                near: routineEventContext.stableId,
                from: routineEventContexts,
                to: sortedListEvents!,
                destinationComparatorId: { $0.routineEventContext?.stableId }
            )

            let sortDate = generateSortDate(
                at: targetIndex,
                in: sortedListEvents!,
                startOfDay: startOfDay
            )

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
        routineEvent: RoutineEventContext,
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
            if let variantPlanner = plannerEvent.routineEventVariant?.planner {
                return Weekday.forDatestamp(variantPlanner.datestamp)
            }
            return Weekday.forDatestamp(planner.datestamp)
        }()

        // MARK: Delete event if its origin weekday has been removed from the routine event.
        // TODO: can this be removed now that relationships handle the deletions immediately?
        //        guard let sourceWeekday,
        //            routineEvent.routineEvent(for: sourceWeekday) != nil
        //        else {
        //            deletePlannerEvent(
        //                plannerEvent,
        //                in: planner,
        //                ekEventStore: ekEventStore
        //            )
        //            return false
        //        }

        return true
    }
}
