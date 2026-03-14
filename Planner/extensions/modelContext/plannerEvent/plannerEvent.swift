//
//  plannerEvent.swift
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

    @MainActor
    func createStorageEvent(
        in events: [PlannerEvent],
        near baseId: UUID?,
        offset: Int,
        startOfDay: DateInRegion,
        settings: PlannerSettings
    ) -> UUID? {

        guard
            let targetIndex = generateTargetIndex(
                in: events,
                near: baseId,
                offset: offset
            )
        else {
            return nil
        }

        let sortDate = generateSortDate(
            plannerStartOfDay: startOfDay,
            index: targetIndex,
            sortedEvents: events
        )

        let newEvent = PlannerEvent(
            date: startOfDay.date,
            sortDate: sortDate
        )
        insert(newEvent)

        self.safeSave("plannerEvent.createStorageEvent")

        return newEvent.stableId
    }

    @MainActor
    func checkPlannerEvent(_ event: PlannerEvent) {
        event.isChecked = true
        self.safeSave("plannerEvent.checkPlannerEvent")
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

        self.safeSave("plannerEvent.deletePlannerEvents")
    }

    @MainActor
    func deleteCheckedPlannerEvents(
        from events: [PlannerEvent],
        ekEventStore: EKEventStore? = nil  // deletes calendar events, otherwise they are preserved.
    ) {
        let checked = events.filter { $0.isChecked }
        self.deletePlannerEvents(checked, ekEventStore: ekEventStore)
        self.safeSave("plannerEvent.deleteCheckedStorageEvents")
    }

    @MainActor
    func movePlannerEvent(
        from: Int,
        to: Int,
        plannerStartOfDay: DateInRegion,
        sortedEvents: [PlannerEvent]
    ) {
        guard from != to else { return }

        let movedEvent = sortedEvents[from]
        movedEvent.sortDate = generateSortDate(
            plannerStartOfDay: plannerStartOfDay,
            index: to,
            sortedEvents: sortedEvents
        )

        self.safeSave("plannerEvent.movePlannerEvent")
    }

    @MainActor
    func handlePlannerEventTitleChange(
        _ event: PlannerEvent,
        plannerStartOfDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {
        event.handleTitleChange(
            startOfDay: plannerStartOfDay,
            eventKitStore: eventKitStore,
            defaultLocation: defaultLocation
        )

        self.safeSave("plannerEvent.handlePlannerEventTitleChange")
    }

    @MainActor
    func transferPlannerEvents(
        _ events: [PlannerEvent],
        days: DateComponents,
        previousDatestamp: String,
        targetDatestamp: String,
        settings: PlannerSettings,
        eventStore: EKEventStore
    ) {

        // Load in the planner for the selected datestamp.
        // This will only be used for untimed events.
        let targetPlanner = loadPlanner(for: targetDatestamp)
        guard
            let targetPlannerStartOfDay = targetPlanner.datestamp.startOfDay(
                in: targetPlanner.region(settings: settings)
            )
        else {
            assertionFailure(
                "ERROR plannerEvent.transferPlannerEvents: Could not build plannerStartOfDay from \(targetDatestamp)"
            )
            return
        }

        // Assemble the events in reverse-chronological ordering so they
        // are inserted correctly.
        let sortedEvents = events.sorted { $0.sortDate > $1.sortDate }

        for event in sortedEvents {

            if let calEvent = event.calendarEvent {

                // Event is a calendar event. Update the calendar.

                guard calEvent.calendar.allowsContentModifications else {
                    print(
                        "Calendar event is read-only. Skipping event: \(event.title)"
                    )
                    continue
                }

                // Shift the start and end dates and save.
                calEvent.startDate = calEvent.startDate + days
                calEvent.endDate = calEvent.endDate + days

                do {
                    try eventStore.save(
                        calEvent,
                        span: .thisEvent,
                        commit: true
                    )
                } catch {
                    assertionFailure(
                        "ERROR plannerEvent.tarnsferPlannerEvents: \(error)"
                    )
                    continue
                }
            }

            if !event.hasTime {

                // Untimed events MUST have their date set to the planner's startOfDay.
                event.date = targetPlannerStartOfDay.date

            } else {
                event.date = event.date + days
            }

            event.sortDate = getSortDate(
                for: event,
                settings: settings,
                previousPlannerDatestamp: previousDatestamp
            )
        }

        self.safeSave("plannerEvent.transferPlannerEvents")
    }

    @MainActor
    func handlePlannerEventChange(
        _ draftPlannerEvent: DraftPlannerEvent,
        previousDatestamp: String?,
        targetDatestamp: String,
        settings: PlannerSettings,
        ekEventStore: EKEventStore,
        initialPlannerEvent: PlannerEvent?,
        initialCalendarEvent: EKEvent?
    ) {

        let event =
            initialPlannerEvent
            ?? PlannerEvent(
                date: draftPlannerEvent.date,
                sortDate: draftPlannerEvent.date
            )

        event.title = draftPlannerEvent.title
        event.hasTime = draftPlannerEvent.hasTime
        event.calendarEvent = nil
        event.calendarItemExternalIdentifier = nil
        event.location = draftPlannerEvent.location
        event.sortDate = getSortDate(
            for: event,
            settings: settings,
            previousPlannerDatestamp: previousDatestamp
        )

        if !event.hasTime {
            let targetPlanner = loadPlanner(
                for: targetDatestamp
            )
            guard
                let targetPlannerStartOfDay = targetPlanner.datestamp
                    .startOfDay(in: targetPlanner.region(settings: settings))
            else {
                assertionFailure(
                    "ERROR: Could not create plannerStartOfDay from \(targetPlanner.datestamp)"
                )
                return
            }

            // Untimed events MUST have their date set to the planner's startOfDay.
            event.date = targetPlannerStartOfDay.date

        } else {
            event.date = draftPlannerEvent.date
        }

        self.insertEventIfNeeded(event)

        // Delete the old calendar event.
        if let initialCalendarEvent {
            let _ = ekEventStore.deleteEvent(initialCalendarEvent)
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.
    }

    @MainActor
    func getSortDate(
        for event: PlannerEvent,
        settings: PlannerSettings,
        previousPlannerDatestamp: String? = nil
    ) -> Date {

        let chronologicalPossibleDatestamps =
            getChronologicalPossibleDatestamps(for: event.date)

        // Priority 1: Reuse the event's existing position if it has not moved.
        if let previousPlannerDatestamp,
            chronologicalPossibleDatestamps.contains(previousPlannerDatestamp)
        {
            return event.sortDate
        }

        guard
            let plannerStartOfDay = self.getEarliestPlannerStartOfDay(
                for: event.date,
                settings: settings
            )
        else {
            // Event does not belong to any planners. Use its actual date as the sortDate.
            return event.date
        }

        let sortedStorageEvents = self.getSortedStorageEvents(
            for: plannerStartOfDay
        )

        // Place the event at the start of its new planner.
        return generateSortDate(
            plannerStartOfDay: plannerStartOfDay,
            index: 0,
            sortedEvents: sortedStorageEvents
        )
    }

    @MainActor
    func getUpperSortDate(for plannerStartOfDay: DateInRegion) -> Date {
        let storageEvents = getSortedStorageEvents(for: plannerStartOfDay)
        return generateSortDate(
            plannerStartOfDay: plannerStartOfDay,
            index: 0,
            sortedEvents: storageEvents
        )
    }

    @MainActor
    func getEarliestPlannerStartOfDay(
        for date: Date,
        settings: PlannerSettings
    ) -> DateInRegion? {

        let chronologicalPossibleDatestamps =
            getChronologicalPossibleDatestamps(for: date)

        for datestamp in chronologicalPossibleDatestamps {

            let planner = loadPlanner(for: datestamp)
            guard
                let plannerStartOfDay = planner.datestamp.startOfDay(
                    in: planner.region(settings: settings)
                )
            else {
                assertionFailure(
                    "ERROR plannerEvent.getEarliestPlannerStartOfDay: Could not build plannerStartOfDay from \(planner.datestamp)"
                )
                continue
            }

            if date.belongsTo(plannerStartOfDay) {
                return plannerStartOfDay
            }
        }

        // Date does not belong to any planner.
        return nil
    }

    // MARK: - Helper Functions

    @MainActor
    private func getSortedStorageEvents(for plannerStartOfDay: DateInRegion)
        -> [PlannerEvent]
    {
        let startOfNextDay = (plannerStartOfDay + 1.days)

        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate {
                        $0.date >= plannerStartOfDay.date
                            && $0.date < startOfNextDay.date
                    },
                    sortBy: [
                        SortDescriptor(\PlannerEvent.sortDate)
                    ]
                )
            )
        } catch {
            assertionFailure(
                "ERROR plannerEvent.getSortedStorageEvents: \(error)"
            )
        }

        return []
    }

    @MainActor
    private func insertEventIfNeeded(_ event: PlannerEvent) {
        guard event.modelContext == nil else { return }
        insert(event)
    }

}
