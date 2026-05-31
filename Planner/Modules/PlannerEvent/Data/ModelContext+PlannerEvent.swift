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
    ) -> UUID? // The ID of the new event.
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
        safeSave("_plannerEventCRUD.createPlannerEvent")

        return newEvent.stableId
    }

    @MainActor
    func createPlannerEvent(
        for calendarEvent: EKEvent,
        in startOfDay: DateInRegion?
    ) {
        if calendarEvent.isAllDay { return }

        let sortDate = {
            if let startOfDay {
                // Event has a target planner. Add it to the top of the list.
                return self.getUpperSortDate(for: startOfDay)
            }
            return calendarEvent.startDate
        }()

        insert(
            PlannerEvent(
                time: calendarEvent.startDate,
                datestamp: startOfDay?.datestamp,
                sortDate: sortDate,
                calendarEvent: calendarEvent
            )
        )

        // Note: Don't save the context.
        // This is only ever called as part of a larger pipeline.
    }

    // MARK: - READ

    @MainActor
    func getSortedStorageEvents(for startOfDay: DateInRegion)
        -> [PlannerEvent]
    {
        let nextDay = startOfDay + 1.days
        let datestamp = startOfDay.datestamp

        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate {
                        if let time = $0.time {
                            return time >= startOfDay.date
                                && time < nextDay.date
                        } else {
                            return $0.datestamp == datestamp
                        }
                    },
                    sortBy: [
                        SortDescriptor(\PlannerEvent.sortDate),
                    ]
                )
            )
        } catch {
            assertionFailure(
                "ERROR _plannerEventCRUD.getSortedStorageEvents: \(error)"
            )
        }

        return []
    }

    // MARK: - UPDATE

    @MainActor
    func updatePlannerEvent(
        with draftPlannerEvent: DraftPlannerEvent,
        sourcePlanner: Planner?,
        targetDatestamp: String,
        settings: PlannerSettings,
        ekEventStore: EKEventStore,
        timeZone: TimeZone,
        sourcePlannerEvent: PlannerEvent?,
        sourceCalendarEvent: EKEvent?
    ) -> String? // The datestamp the event is now in.
    {
        let event =
            sourcePlannerEvent
                ?? PlannerEvent(
                    sortDate: draftPlannerEvent.date
                )

        event.title = draftPlannerEvent.title.trimmed
        event.location = draftPlannerEvent.location
        event.calendarEvent = nil
        event.calendarItemExternalIdentifier = nil
        event.datestamp = targetDatestamp
        event.time = draftPlannerEvent.hasTime ? draftPlannerEvent.date : nil

        let destinationDatestamp = ensureValidSortDate(
            for: event,
            settings: settings,
            sourceDatestamp: sourcePlanner?.datestamp
        )

        if let sourcePlanner {
            updatePlannerEventRoutineVariance(
                event,
                sourceCalendarEvent: sourceCalendarEvent,
                in: timeZone,
                sourcePlanner: sourcePlanner
            )
        }

        insertIfNeeded(event)

        // Delete the old calendar event.
        if let sourceCalendarEvent {
            _ = ekEventStore.attemptDeleteEvent(sourceCalendarEvent)
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDatestamp
    }

    /// Note: This function will only be called if no calendar event exists.
    @MainActor
    func updatePlannerEventRoutineVariance(
        _ plannerEvent: PlannerEvent,
        sourceCalendarEvent: EKEvent? = nil,
        in timeZone: TimeZone,
        sourcePlanner: Planner
    ) {
        let routineEvent: RoutineEvent? = {
            if let existing = plannerEvent.routineEvent {
                return existing
            }
            if let sourceCalendarEventId = sourceCalendarEvent?
                .calendarItemExternalIdentifier
            {
                return loadRoutineEvent(for: sourceCalendarEventId)
            }
            return nil
        }()

        if let routineEvent {
            let isRoutineEventVariant = !plannerEvent.matches(
                routineEvent,
                in: timeZone
            )

            if isRoutineEventVariant {
                if let existingVariant = plannerEvent.routineEventVariant {
                    existingVariant.calendarItemExternalIdentifier = nil
                } else {
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
            } else {
                if let existingVariant = plannerEvent.routineEventVariant {
                    delete(existingVariant)
                }
            }
        }
    }

    /// Ensures that moved events end up at the top of their new planner day.
    @MainActor
    func ensureValidSortDate(
        for event: PlannerEvent,
        settings: PlannerSettings,
        sourceDatestamp: String? = nil
    ) -> String? // The destination datestamp the event is now in.
    {
        guard
            let startOfDay = getEarliestPlannerStartOfDay(
                for: event.time,
                datestamp: event.datestamp,
                settings: settings
            )
        else {
            // Event does not belong to any planners. Use its actual time as the sortDate.
            event.sortDate = event.time ?? Date()
            return nil
        }

        if let sourceDatestamp,
           startOfDay.datestamp == sourceDatestamp
        {
            // The event has not moved planners. Reuse the event's existing position.
            return sourceDatestamp
        }

        let sortedStorageEvents = getSortedStorageEvents(
            for: startOfDay
        )

        // Place the event at the start of its new planner.
        event.sortDate = generateSortDate(
            at: 0,
            in: sortedStorageEvents,
            startOfDay: startOfDay
        )

        return startOfDay.datestamp
    }

    @MainActor
    func movePlannerEvent(
        from: Int,
        to: Int,
        startOfDay: DateInRegion,
        sortedPendingPlannerEvents: [PlannerEvent],
        sortedPlannerEvents: [PlannerEvent]
    ) {
        let movedEvent = sortedPendingPlannerEvents[from]
        movedEvent.sortDate = generateSortDate(
            at: to,
            in: sortedPlannerEvents,
            startOfDay: startOfDay
        )

        safeSave("_plannerEventCRUD.movePlannerEvent")
    }

    // MARK: - DELETE

    @MainActor
    func deletePlannerEvents(
        _ events: [PlannerEvent],
        in planner: Planner,

        // Deletes calendar events if defined, otherwise they are preserved.
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

        safeSave("_plannerEventCRUD.deletePlannerEvents")
    }

    @MainActor
    func deletePlannerEvent(
        _ event: PlannerEvent,

        // Marks routine events as variants so they are not synced.
        in planner: Planner,

        // Deletes calendar events, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil,

        skipSave: Bool = false
    ) {
        if let calendarEvent = event.calendarEvent, let ekEventStore,
           !ekEventStore.attemptDeleteEvent(calendarEvent)
        {
            return
        }

        if let routineEvent = event.routineEvent,
           event.routineEventVariant == nil,

           // Variants do not need to be created when routine is excluded.
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
            safeSave("_plannerEventCRUD.deletePlannerEvent")
        }
    }
}
