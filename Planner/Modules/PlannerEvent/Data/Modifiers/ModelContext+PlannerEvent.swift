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
        let sortDate = generatePlannerEventSortDate(
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
                "ERROR ModelContext+PlannerEvent getCalendarRecords startOfDay: \(error)"
            )
        }

        return []
    }

    func getCalendarRecords(for calendarItemExternalIdentifiers: Set<String>, onOrAfter: Date)
        -> [PlannerEvent]
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: PlannerEvent.calendarRecords(
                        for: calendarItemExternalIdentifiers,
                        onOrAfter: onOrAfter
                    )
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+PlannerEvent getCalendarRecords calendarItemExternalIdentifier: \(error)"
            )
        }

        return []
    }

    // MARK: - UPDATE

    /// Ensures that moved events end up at the top of their new planner day.
    @MainActor
    func ensureValidSortDate(
        for plannerEvent: PlannerEvent,
        sourceDatestamp: String? = nil,
        settings: Settings
    ) -> /// The datestamps the event is now in.
        Set<String>
    {
        let sortedStartsOfDays = getSortedPlannerStartOfDays(
            for: plannerEvent.time,
            endTime: plannerEvent.eKEventContext?.endDate,
            datestamp: plannerEvent.datestamp,
            settings: settings
        )

        if let eKEventContext = plannerEvent.eKEventContext,
            eKEventContext.isAllDay
        {
            // Event is all-day. Use its actual time as the sortDate.
            plannerEvent.sortDate = eKEventContext.startDate
            return Set(sortedStartsOfDays.map(\.datestamp))
        }

        guard let earliestStartOfDay = sortedStartsOfDays.first
        else {
            // Event does not belong to any planners. Use its actual time as the sortDate.
            plannerEvent.sortDate =
                plannerEvent.time ?? sourceDatestamp?.date ?? Date()
            return []
        }

        let startsOfDaysSet = Set(sortedStartsOfDays.map(\.datestamp))

        if let sourceDatestamp,
            startsOfDaysSet.contains(sourceDatestamp)
        {
            // The event has not moved planners. Reuse the event's existing sort date.
            return startsOfDaysSet
        }

        let sortedListEvents = getSortedListEvents(
            on: earliestStartOfDay
        )

        // Place the event at the top of its earliest planner.
        plannerEvent.sortDate = generatePlannerEventSortDate(
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

        movedEvent.sortDate = generatePlannerEventSortDate(
            at: targetIndex,
            in: sortedPlannerEvents,
            startOfDay: startOfDay
        )

        safeSave("ModelContext+PlannerEvent movePlannerEvent")
    }

    // MARK: - DELETE

    func deletePlannerEvents(
        _ plannerEvents: [PlannerEvent],
        /// Deletes calendar events if defined, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil
    ) {
        for plannerEvent in plannerEvents {
            deletePlannerEvent(
                plannerEvent,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }

        safeSave("ModelContext+PlannerEvent deletePlannerEvents")
    }

    @MainActor
    func deleteCalendarRecords(
        externalIds: Set<String>,
        onOrAfter: Date
    ) {
        safeBulkDelete(
            getCalendarRecords(
                for: externalIds,
                onOrAfter: onOrAfter
            )
        )
    }
}
