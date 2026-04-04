//
//  _plannerEventCRUD.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    // MARK: - CREATE

    @MainActor
    func createPlannerEvent(
        at index: Int,
        in events: [PlannerEvent],
        startOfDay: DateInRegion
    ) -> UUID?  // The ID of the new event.
    {

        let sortDate = generateSortDate(
            at: index,
            in: events,
            plannerDay: startOfDay
        )

        let newEvent = PlannerEvent(
            date: startOfDay.date,
            sortDate: sortDate
        )

        insert(newEvent)
        self.safeSave("_plannerEventCRUD.createPlannerEvent")

        return newEvent.stableId
    }

    @MainActor
    func createPlannerEvent(
        for calendarEvent: EKEvent,
        in plannerDay: DateInRegion?
    ) {
        if calendarEvent.isAllDay { return }

        let sortDate = {
            if let plannerDay {
                // Event has a target planner. Add it to the top of the list.
                return self.getUpperSortDate(for: plannerDay)
            }
            return calendarEvent.startDate
        }()

        insert(
            PlannerEvent(
                date: calendarEvent.startDate,
                sortDate: sortDate,
                calendarEvent: calendarEvent
            )
        )

        // Note: Don't save the context.
        // This is only ever called as part of a larger pipeline.
    }

    // MARK: - READ

    @MainActor
    func getSortedStorageEvents(for plannerDay: DateInRegion)
        -> [PlannerEvent]
    {
        let nextDay = plannerDay + 1.days

        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate {
                        $0.date >= plannerDay.date
                            && $0.date < nextDay.date
                    },
                    sortBy: [
                        SortDescriptor(\PlannerEvent.sortDate)
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
        _ draftPlannerEvent: DraftPlannerEvent,
        sourceDatestamp: String?,
        targetDatestamp: String,
        settings: PlannerSettings,
        ekEventStore: EKEventStore,
        sourcePlannerEvent: PlannerEvent?,
        sourceCalendarEvent: EKEvent?
    ) -> String?  // The datestamp the event is now in.
    {

        let event =
            sourcePlannerEvent
            ?? PlannerEvent(
                date: draftPlannerEvent.date,
                sortDate: draftPlannerEvent.date
            )

        event.title = draftPlannerEvent.title
        event.hasTime = draftPlannerEvent.hasTime
        event.location = draftPlannerEvent.location
        event.calendarEvent = nil
        event.calendarItemExternalIdentifier = nil

        if !event.hasTime {
            let targetPlanner = self.getPlanner(
                for: targetDatestamp
            )

            guard
                let destinationDay = targetPlanner.datestamp
                    .startOfDay(in: targetPlanner.region(settings: settings))
            else {
                return sourceDatestamp
            }

            // Untimed events MUST have their date set to the planner's startOfDay.
            event.date = destinationDay.date

        } else {
            event.date = draftPlannerEvent.date
        }

        let destinationDatestamp = self.ensureValidSortDate(
            for: event,
            settings: settings,
            sourceDatestamp: sourceDatestamp
        )

        self.insertIfNeeded(event)

        // Delete the old calendar event.
        if let sourceCalendarEvent {
            let _ = ekEventStore.deleteEvent(sourceCalendarEvent)
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDatestamp
    }

    @MainActor
    func ensureValidSortDate(
        for event: PlannerEvent,
        settings: PlannerSettings,
        sourceDatestamp: String? = nil
    ) -> String?  // The destination datestamp the event is now in.
    {

        guard
            let plannerDay = self.getEarliestPlannerDay(
                for: event.date,
                settings: settings,
                requireExactMatch: !event.hasTime
            )
        else {
            // Event does not belong to any planners. Use its actual date as the sortDate.
            event.sortDate = event.date
            return nil
        }

        if let sourceDatestamp,
            plannerDay.datestamp == sourceDatestamp
        {
            // The event has not moved planners. Reuse the event's existing position.
            return sourceDatestamp
        }

        let sortedStorageEvents = self.getSortedStorageEvents(
            for: plannerDay
        )

        // Place the event at the start of its new planner.
        event.sortDate = generateSortDate(
            at: 0,
            in: sortedStorageEvents,
            plannerDay: plannerDay
        )

        return plannerDay.datestamp
    }

    @MainActor
    func cancelPlannerEvent(_ event: PlannerEvent) {
        event.isCanceled = true
        self.safeSave("_plannerEventCRUD.cancelPlannerEvent")
    }

    @MainActor
    func movePlannerEvent(
        from: Int,
        to: Int,
        plannerDay: DateInRegion,
        sortedEvents: [PlannerEvent]
    ) {
        guard from != to else { return }

        let movedEvent = sortedEvents[from]
        movedEvent.sortDate = generateSortDate(
            at: to,
            in: sortedEvents,
            plannerDay: plannerDay
        )

        self.safeSave("_plannerEventCRUD.movePlannerEvent")
    }

    // MARK: - DELETE

    @MainActor
    func deleteCalendarEvent(_ event: PlannerEvent, ekEventStore: EKEventStore)
    {
        guard let calEvent = event.calendarEvent else {
            return
        }

        if ekEventStore.deleteEvent(calEvent) {
            self.delete(event)
        }

        self.safeSave("_plannerEventCRUD.deleteCalendarEvent")
    }

    @MainActor
    func deletePlannerEvents(
        _ events: [PlannerEvent],
        ekEventStore: EKEventStore? = nil  // deletes calendar events, otherwise they are preserved
    ) {
        for event in events {
            if let calendarEvent = event.calendarEvent {
                guard let ekEventStore else {
                    continue
                }

                if !ekEventStore.deleteEvent(calendarEvent) {
                    continue
                }
            }
            self.delete(event)
        }

        self.safeSave("_plannerEventCRUD.deletePlannerEvents")
    }
    
}
