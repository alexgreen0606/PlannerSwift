//
//  ModelContext+PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    // MARK: - CREATE

    @MainActor
    func createPlannerEvent(
        at index: Int,
        in sortedPlannerEvents: [PlannerEvent],
        startOfDay: DateInRegion
    ) ->  // The ID of the new event.
        UUID?
    {
        let sortDate = generateSortDate(
            at: index,
            in: sortedPlannerEvents,
            startOfDay: startOfDay
        )

        let newEvent = PlannerEvent(
            datestamp: startOfDay.datestamp,
            sortDate: sortDate
        )

        insert(newEvent)

        safeSave("ModelContext+PlannerEvent.createPlannerEvent")

        return newEvent.stableId
    }

    @MainActor
    func createPlannerEvent(
        for ekEvent: EKEvent,
        on startOfDay: DateInRegion?
    ) {
        let sortDate = {
            guard !ekEvent.isAllDay, let startOfDay else {
                return ekEvent.startDate ?? Date.now
            }

            // Event has a target planner. Add it to the top of the list.
            return getUpperSortDate(for: startOfDay)
        }()

        insert(
            PlannerEvent(
                time: ekEvent.startDate,
                datestamp: startOfDay?.datestamp,
                sortDate: sortDate,
                calendarEvent: ekEvent
            )
        )

        // Note: Don't save the context.
        // This is only ever called as part of a larger pipeline.
    }

    // MARK: - READ

    func getSortedListEvents(on startOfDay: DateInRegion)
        -> [PlannerEvent]
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: PlannerEvent.listEvents(on: startOfDay),
                    sortBy: [
                        SortDescriptor(\PlannerEvent.sortDate)
                    ]
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+PlannerEvent.getSortedListEvents: \(error)"
            )
        }

        return []
    }

    func getCalendarEvents(on startOfDay: DateInRegion)
        -> [PlannerEvent]
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: PlannerEvent.calendarRecords(on: startOfDay)
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+PlannerEvent.getCalendarEvents: \(error)"
            )
        }

        return []
    }

    // MARK: - UPDATE

    /// Note: This function will only be called if no calendar event exists.
    @MainActor
    func updatePlannerEventRoutineVariance(
        _ plannerEvent: PlannerEvent,
        in timeZone: TimeZone,
        sourcePlanner: Planner,
        staleCalendarItemExternalIdentifier: String? = nil,
        settings: PlannerSettings
    ) {
        let existingVariant: RoutineEventVariant? = {
            if let existing = plannerEvent.routineEventVariant {
                // Event is already a variant.
                return existing
            }

            if let staleCalendarItemExternalIdentifier {
                // Event was previously a calendar event. Check if a variant record exists for that calendar event.
                return loadRoutineEventVariant(
                    for: staleCalendarItemExternalIdentifier
                )
            }

            return nil
        }()

        guard
            let routineEvent: RoutineEvent = plannerEvent.routineEvent
                ?? existingVariant?.routineEvent
        else {
            return
        }

        // MARK: Check if the event differs from the routine event.

        let isRoutineEventVariant = !plannerEvent.matches(
            routineEvent,
            in: timeZone,
            originPlanner: existingVariant?.planner ?? sourcePlanner,
            settings: settings
        )

        if isRoutineEventVariant {
            if let existingVariant {
                // MARK: Clear any link to a stale calendar event.

                existingVariant.calendarItemExternalIdentifier = nil

            } else {
                // MARK: Create a new variance record so this even is not synced with the routine event.

                let routineEventVariant = RoutineEventVariant(
                    routineEvent: routineEvent,
                    planner: sourcePlanner,
                    plannerEvent: plannerEvent
                )

                routineEvent.variants?.append(routineEventVariant)
                sourcePlanner.routineEventVariants?.append(
                    routineEventVariant
                )
                plannerEvent.routineEventVariant = routineEventVariant

                insert(routineEventVariant)
            }
        } else if let existingVariant {
            // MARK: Event is no longer a variant. Delete the variance record.

            delete(existingVariant)

        }
    }

    /// Ensures that moved events end up at the top of their new planner day.
    @MainActor
    func ensureValidSortDate(
        for event: PlannerEvent,
        settings: PlannerSettings,
        sourceDatestamp: String? = nil
    ) -> /// The datestamps the event is now in.
        Set<String>
    {
        let sortedStartsOfDays = getSortedPlannerStartOfDays(
            for: event.time,
            endTime: event.calendarContext?.endDate,
            datestamp: event.datestamp,
            settings: settings
        )

        guard !sortedStartsOfDays.isEmpty
        else {
            // Event does not belong to any planners. Use its actual time as the sortDate.
            event.sortDate = event.time ?? sourceDatestamp?.date ?? Date()
            return []
        }

        let startsOfDaysSet = Set(sortedStartsOfDays.map(\.datestamp))

        if let sourceDatestamp,
            startsOfDaysSet.contains(sourceDatestamp)
        {
            // The event has not moved planners. Reuse the event's existing position.
            return startsOfDaysSet
        }

        let earliestStartOfDay = sortedStartsOfDays.first!

        let sortedListEvents = getSortedListEvents(
            on: earliestStartOfDay
        )

        // Place the event at the start of its earliest planner.
        event.sortDate = generateSortDate(
            at: 0,
            in: sortedListEvents,
            startOfDay: earliestStartOfDay
        )

        return startsOfDaysSet
    }

    @MainActor
    func movePlannerEvent(
        /// The initial index within sortedPendingPlannerEvents.
        initialIndex: Int,
        /// The target index within sortedPlannerEvents.
        targetIndex: Int,
        sortedPendingPlannerEvents: [PlannerEvent],
        sortedPlannerEvents: [PlannerEvent],
        startOfDay: DateInRegion
    ) {
        let movedEvent = sortedPendingPlannerEvents[initialIndex]
        movedEvent.sortDate = generateSortDate(
            at: targetIndex,
            in: sortedPlannerEvents,
            startOfDay: startOfDay
        )

        safeSave("ModelContext+PlannerEvent.movePlannerEvent")
    }

    // MARK: - DELETE

    @MainActor
    func deletePlannerEvent(
        _ event: PlannerEvent,
        /// Marks routine events as variants so they are not synced.
        in planner: Planner,
        /// Deletes calendar events, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil,
        skipSave: Bool = false
    ) {
        if let calendarItemExternalIdentifier = event.calendarContext?
            .calendarItemExternalIdentifier,
            let ekEventStore,
            !ekEventStore.attemptDeleteEvent(
                identifier: calendarItemExternalIdentifier
            )
        {
            return
        }

        if let routineEvent = event.routineEvent,
            event.routineEventVariant == nil,
            // Note: Variants should not be created when routine is excluded.
            !planner.safeExcludeRoutine
        {
            // Mark this routine event as a variant so it is not synced after deletion.
            let routineEventVariant = RoutineEventVariant(
                routineEvent: routineEvent,
                planner: planner
            )

            routineEvent.variants?.append(routineEventVariant)
            planner.routineEventVariants?.append(routineEventVariant)

            insert(routineEventVariant)
        }

        delete(event)

        if !skipSave {
            safeSave("ModelContext+PlannerEvent.deletePlannerEvent")
        }
    }

    func deletePlannerEvents(
        _ events: [PlannerEvent],
        in planner: Planner,
        /// Deletes calendar events if defined, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil
    ) {
        for event in events {
            deletePlannerEvent(
                event,
                in: planner,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }

        safeSave("ModelContext+PlannerEvent.deletePlannerEvents")
    }

    func deletePlannerEventIfExists(
        _ event: PlannerEvent?,
        in planner: Planner,
        ekEventStore: EKEventStore
    ) {
        if let event {
            deletePlannerEvent(
                event,
                in: planner,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }
    }
}
