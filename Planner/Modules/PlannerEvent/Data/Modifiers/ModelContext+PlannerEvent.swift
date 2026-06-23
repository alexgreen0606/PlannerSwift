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
    ) -> /// The ID of the new event.
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

        safeSave("ModelContext+PlannerEvent createPlannerEvent")

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
                ekEvent: ekEvent,
                sortDate: sortDate
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
                "ERROR ModelContext+PlannerEvent getSortedListEvents: \(error)"
            )
        }

        return []
    }

    func getPlannerEvents(on startOfDay: DateInRegion)
        -> [PlannerEvent]
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: PlannerEvent.plannerEvents(on: startOfDay)
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+PlannerEvent getPlannerEvents: \(error)"
            )
        }

        return []
    }

    func getCalendarRecords(on startOfDay: DateInRegion)
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
                "ERROR ModelContext+PlannerEvent getCalendarRecords[date]: \(error)"
            )
        }

        return []
    }

    func getCalendarRecords(for calendarItemExternalIdentifiers: Set<String>)
        -> [PlannerEvent]
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: PlannerEvent.calendarRecords(
                        for: calendarItemExternalIdentifiers
                    )
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+PlannerEvent getCalendarRecords[id]: \(error)"
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
                return getRoutineEventVariant(
                    for: staleCalendarItemExternalIdentifier
                )
            }

            return nil
        }()

        guard
            let routineEvent = plannerEvent.routineEvent
                ?? existingVariant?.routineEvent,
            let routineEventContext = routineEvent.routineEventContext
        else {
            return
        }

        // MARK: Check if the event differs from the routine event.

        let isRoutineEventVariant = !plannerEvent.matches(
            routineEventContext,
            in: timeZone,
            originPlanner: existingVariant?.planner ?? sourcePlanner,
            settings: settings
        )

        if isRoutineEventVariant {
            if existingVariant == nil {
                // MARK: Create a new variance record so this even is not synced with the routine event.
                insert(
                    RoutineEventVariant(
                        routineEvent: routineEvent,
                        planner: sourcePlanner,
                        plannerEvent: plannerEvent
                    )
                )
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
        if let eKEventContext = event.eKEventContext, eKEventContext.isAllDay
        {
            // Event is all-day. Use its actual time as the sortDate.
            event.sortDate = eKEventContext.startDate
            return Set(
                getSortedPlannerStartOfDays(
                    for: event.time,
                    endTime: event.eKEventContext?.endDate,
                    datestamp: event.datestamp,
                    settings: settings
                ).map(\.datestamp)
            )
        }

        let sortedStartsOfDays = getSortedPlannerStartOfDays(
            for: event.time,
            endTime: event.eKEventContext?.endDate,
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

        safeSave("ModelContext+PlannerEvent movePlannerEvent")
    }

    // MARK: - DELETE

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

        safeSave("ModelContext+PlannerEvent deletePlannerEvents")
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
    
    @MainActor
    func deleteCalendarRecords(
        calendarItemExternalIdentifiers: Set<String>
    ) {
        let calendarRecords = getCalendarRecords(
            for: calendarItemExternalIdentifiers
        )
        
        for calendarRecord in calendarRecords {
            delete(calendarRecord)
        }
    }
}
