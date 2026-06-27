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

        // MARK: - Delete All Routine Records If Routine Is Excluded

        if planner.safeExcludeRoutine {

            var staleCalendarItemExternalIdentifiers: Set<String> = []

            // Delete each record, including linked calendar events.
            // Keep completed events.
            for routineEventRecordContext in planner
                .safeRoutineEventRecordContexts
            {
                guard let plannerEvent = routineEventRecordContext.plannerEvent
                else { continue }

                routineEventRecordContext.plannerEvent =
                    prepareRoutineEventRecordForDeletion(
                        plannerEvent,
                        staleCalendarItemExternalIdentifiers:
                            &staleCalendarItemExternalIdentifiers,
                        ekEventStore: ekEventStore
                    )

                delete(routineEventRecordContext)
            }

            planner.routineEventRecordContexts = []

            // Delete all planner events linked to the deleted calendar events.
            deleteCalendarRecords(
                calendarItemExternalIdentifiers:
                    staleCalendarItemExternalIdentifiers
            )

            return
        }

        // MARK: - Skip Synchronization Of Past Planners

        if planner.datestamp < todaystamp {
            // Past routine events will never change.
            return
        }

        // MARK: - Sync Existing Planner Events

        var invalidatedPositionPlannerEvents: [PlannerEvent] = []

        /// Includes chip events and list events.
        let plannerEvents = getPlannerEvents(on: startOfDay)

        for plannerEvent in plannerEvents {
            guard
                !plannerEvent.isCompleted,
                let routineEventRecordContext = plannerEvent
                    .routineEventRecordContext,
                let routineEvent = routineEventRecordContext.routineEvent,
                let routineEventContext = routineEvent.routineEventContext
            else {
                continue
            }

            // Invalidate planner event position if its routine event position has changed.
            // Don't invalidate events that didn't originate from this planner.
            if routineEventRecordContext.syncedSortDateVersion
                != routineEvent.sortDateVersion,
                routineEventRecordContext.planner === planner
            {
                invalidatedPositionPlannerEvents.append(plannerEvent)
            }

            // Sync with routine event.
            plannerEvent.syncWithRoutineEvent(
                on: startOfDay
            )
        }

        var sortedRoutineEventContexts: [RoutineEventContext]?
        var sortedListEvents: [PlannerEvent]?

        // MARK: - Re-position Moved Routine Events

        if !invalidatedPositionPlannerEvents.isEmpty {

            sortedListEvents = getSortedListEvents(on: startOfDay)
            sortedRoutineEventContexts = getSortedRoutineEventContexts(
                for: routine
            )

            for plannerEvent in invalidatedPositionPlannerEvents {
                guard
                    let routineEventRecordContext = plannerEvent
                        .routineEventRecordContext,
                    let routineEvent = routineEventRecordContext.routineEvent,
                    let routineEventContext = routineEvent.routineEventContext,
                    let safeSortedListEvents = sortedListEvents,
                    let sortedRoutineEventContexts
                else {
                    continue
                }

                // Find a position for the event closest to its routine siblings.
                let targetIndex = generateRoutineEventIndex(
                    near: routineEventContext.stableId,
                    from: sortedRoutineEventContexts,
                    to: safeSortedListEvents,
                    destinationComparatorId: {
                        $0.routineEventRecordContext?.routineEvent?
                            .routineEventContext?.stableId
                    }
                )

                plannerEvent.sortDate = generateSortDate(
                    at: targetIndex,
                    in: safeSortedListEvents,
                    startOfDay: startOfDay
                )

                // Sync the planner event's sort date version.
                routineEventRecordContext.syncedSortDateVersion =
                    routineEvent.sortDateVersion

                // Track the event at its new position in the planner.
                sortedListEvents?.insert(plannerEvent, at: targetIndex)
            }
        }

        // MARK: - Create New Routine Events

        let existingRoutineEventContextIds: Set<UUID> = Set(
            planner.safeRoutineEventRecordContexts.compactMap(
                \.routineEvent?.routineEventContext?.stableId
            )
        )

        let missingReverseSortedRoutineEvents =
            getSortedRoutineEvents(
                for: routine,
                excluding: existingRoutineEventContextIds,
                reversed: true
            )

        guard !missingReverseSortedRoutineEvents.isEmpty
        else {
            return
        }

        sortedListEvents =
            sortedListEvents
            ?? getSortedListEvents(on: startOfDay)

        sortedRoutineEventContexts =
            sortedRoutineEventContexts
            ?? getSortedRoutineEventContexts(for: routine)

        for routineEvent in missingReverseSortedRoutineEvents {
            guard
                let routineEventContext = routineEvent.routineEventContext,
                let sortedRoutineEventContexts
            else {
                continue
            }

            // Find a position for the routine event record closest to its routine siblings.
            // Defaults to top of list otherwise.
            let targetIndex = generateRoutineEventIndex(
                near: routineEventContext.stableId,
                from: sortedRoutineEventContexts,
                to: sortedListEvents!,
                destinationComparatorId: {
                    $0.routineEventRecordContext?.routineEvent?
                        .routineEventContext?.stableId
                }
            )

            let sortDate = generateSortDate(
                at: targetIndex,
                in: sortedListEvents!,
                startOfDay: startOfDay
            )

            let newEvent =
                PlannerEvent(
                    routineEvent: routineEvent,
                    planner: planner,
                    startOfDay: startOfDay,
                    sortDate: sortDate,
                )

            insert(newEvent)

            // Track the event at its position in the planner.
            sortedListEvents!.insert(newEvent, at: targetIndex)
        }
    }
}
