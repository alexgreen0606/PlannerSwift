//
//  plannerEvent.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {

    // MARK: - Create New Events

    @MainActor
    func createStorageEvent(
        in events: [PlannerEvent],
        near baseId: UUID?,
        offset: Int,
        startOfDay: DateInRegion,
        settings: PlannerSettings
    ) -> UUID? {

        var targetIndex: Int? = 0

        if let baseId {
            targetIndex = generateTargetIndex(
                in: events,
                near: baseId,
                offset: offset
            )
        }

        guard let targetIndex else {
            return nil
        }

        let sortDate = generateSortDate(
            startOfDay: startOfDay,
            index: targetIndex,
            events: events
        )

        let newEvent = PlannerEvent(
            date: startOfDay.date,
            sortDate: sortDate
        )

        insert(newEvent)

        // TODO; really?? : Task makes the UI smoother as new events animate in.
        Task { @MainActor in
            do {
                try self.save()
            } catch {
                print("ERROR plannerEvent.createStorageEvent: \(error)")
            }
        }

        return newEvent.stableId
    }

    @MainActor
    func addCalendarEventToPlanner(
        _ calendarEvent: EKEvent,
        plannerStartOfDay: DateInRegion
    ) {

        guard
            let calendarItemExternalIdentifier = calendarEvent
                .calendarItemExternalIdentifier
        else {
            assertionFailure(
                "ERROR plannerEvent.addCalendarEventToPlanner: Calendar event does not have an external identifier."
            )
            return
        }

        let descriptor = FetchDescriptor<PlannerEvent>(
            predicate: #Predicate<PlannerEvent> {
                if let calId = $0.calendarItemExternalIdentifier {
                    return calId == calendarItemExternalIdentifier
                } else {
                    return false
                }
            }
        )

        do {
            let storageEvents = try fetch(descriptor)

            guard let storageEvent = storageEvents.first else {
                createCalendarPlannerEvent(
                    for: calendarEvent,
                    in: plannerStartOfDay
                )
                return
            }

            storageEvent.syncWithCalendarEvent(calendarEvent)
            storageEvent.sortDate = getUpperSortDate(for: plannerStartOfDay)

        } catch {
            createCalendarPlannerEvent(
                for: calendarEvent,
                in: plannerStartOfDay
            )
        }
    }

    // TODO: what about calendar events?
    @MainActor
    func deleteStorageEvents(_ events: [PlannerEvent]) {

        for event in events {
            delete(event)
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.deleteStorageEvents: \(error)"
            )
        }
    }

    // TODO: what about calendar events?
    @MainActor
    func deleteCheckedStorageEvents(from events: [PlannerEvent]) {

        for event in events {
            if event.isChecked {
                delete(event)
            }
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.deleteCheckedStorageEvents: \(error)"
            )
        }
    }

    // MARK: - List Handlers

    @MainActor
    func movePlannerEvent(
        from: Int,
        to: Int,
        startOfDay: DateInRegion,
        events: [PlannerEvent]
    ) {
        guard from != to else { return }

        // Save the event to its new position. Preserve the actual event date.
        let movedEvent = events[from]
        let eventsWithoutEvent = events.filter {
            $0.stableId != movedEvent.stableId
        }
        movedEvent.sortDate = generateSortDate(
            startOfDay: startOfDay,
            index: to,
            events: eventsWithoutEvent
        )

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR: plannerEvent.movePlannerEvent: \(error)"
            )
        }
    }

    @MainActor
    func handlePlannerEventTitleChange(
        _ event: PlannerEvent,
        startOfDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {

        event.handleTitleChange(
            startOfDay: startOfDay,
            eventKitStore: eventKitStore,
            defaultLocation: defaultLocation
        )

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR: plannerEvent.handlePlannerEventTitleChange: \(error)"
            )
        }
    }

    // MARK: - Form Handlers

    @MainActor
    func transferPlannerEvents(
        _ events: [PlannerEvent],
        days: DateComponents,
        previousDatestamp: String,
        targetDatestamp: String,
        settings: PlannerSettings,
        eventStore: EKEventStore
    ) {

        // Used for untimed events only.
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

        let sortedEvents = events.sorted { $0.sortDate > $1.sortDate }

        for event in sortedEvents {

            if let calEvent = event.calendarEvent {
                guard calEvent.calendar.allowsContentModifications else {
                    print(
                        "Calendar event is read-only. Skipping event: \(event.title)"
                    )
                    continue
                }

                // Shift start and end dates
                calEvent.startDate = calEvent.startDate + days
                calEvent.endDate = calEvent.endDate + days

                do {
                    try eventStore.save(
                        calEvent,
                        span: .thisEvent,
                        commit: true
                    )
                } catch {
                    print("ERROR plannerEvent.tarnsferPlannerEvents: \(error)")
                    continue
                }
            }

            if !event.hasTime {

                // Untimed events MUST have their date set to the planner's startOfDay.
                event.date = targetPlannerStartOfDay.date

            } else {
                event.date = event.date + days
            }

            event.sortDate = getUpperSortDateIfNewToPlanner(
                for: event,
                settings: settings,
                previousPlannerDatestamp: previousDatestamp
            )
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.transferPlannerEvents: \(error)"
            )
        }
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

        if draftPlannerEvent.hasTime && draftPlannerEvent.location == nil {
            assertionFailure(
                "ERROR plannerEvent.handlePlannerEventChange: Draft event must have a location assigned if it has a time."
            )
            return
        }

        let event =
            initialPlannerEvent
            ?? PlannerEvent(
                date: draftPlannerEvent.date,
                sortDate: draftPlannerEvent.date
            )

        if !event.hasTime {

            let targetPlanner = loadPlanner(for: targetDatestamp)

            guard
                let targetPlannerStartOfDay = targetPlanner.datestamp
                    .startOfDay(in: targetPlanner.region(settings: settings))
            else {
                assertionFailure(
                    "ERROR: Could not create plannerStartOfDay from \(targetPlanner.datestamp)"
                )
                return
            }

            // Set the untimed event's date to the start of its planner.
            event.date = targetPlannerStartOfDay.date

        } else {
            event.date = draftPlannerEvent.date
        }

        event.title = draftPlannerEvent.title
        event.hasTime = draftPlannerEvent.hasTime
        event.calendarEvent = nil
        event.location = draftPlannerEvent.location
        event.sortDate = getUpperSortDateIfNewToPlanner(
            for: event,
            settings: settings,
            previousPlannerDatestamp: previousDatestamp
        )

        insertEventIfNeeded(event)

        // Delete the old calendar event.
        if let initialCalendarEvent {
            ekEventStore.deleteEvent(initialCalendarEvent)
        }

        // Note: Saving the context here will delete the location. Allow the model context to auto-save when needed.

    }

    @MainActor
    func handleCalendarEventChange(
        _ calendarEvent: EKEvent?,
        previousDatestamp: String?,
        initialPlannerEvent: PlannerEvent?,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) {

        if let initialPlannerEvent {
            guard let calendarEvent, !calendarEvent.isAllDay else {
                delete(initialPlannerEvent)
                return
            }

            initialPlannerEvent.syncWithCalendarEvent(calendarEvent)
            initialPlannerEvent.sortDate = getUpperSortDateIfNewToPlanner(
                for: initialPlannerEvent,
                settings: settings,
                previousPlannerDatestamp: previousDatestamp
            )

        } else if let calendarEvent {

            let plannerStartOfDay: DateInRegion? = {
                guard
                    let (planner, plannerStartOfDay) = getEarliestPlanner(
                        for: calendarEvent.startDate,
                        settings: settings
                    )
                else {
                    return nil
                }
                return plannerStartOfDay
            }()
            createCalendarPlannerEvent(
                for: calendarEvent,
                in: plannerStartOfDay
            )

        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.handleCalendarEventChange: \(error)"
            )
        }
    }

    // MARK: - Helper Functions

    @MainActor
    private func getSortedStorageEvents(for plannerStartOfDay: DateInRegion)
        -> [PlannerEvent]
    {

        let startOfNextDay = (plannerStartOfDay + 1.days)

        let descriptor = FetchDescriptor<PlannerEvent>(
            predicate: #Predicate {
                $0.date >= plannerStartOfDay.date
                    && $0.date < startOfNextDay.date
            },
            sortBy: [
                SortDescriptor(\PlannerEvent.sortDate)
            ]
        )

        do {
            return try fetch(descriptor)
        } catch {
            assertionFailure(
                "ERROR plannerEvent.getSortedStorageEvents: \(error)"
            )
        }

        return []
    }

    @MainActor
    private func getUpperSortDateIfNewToPlanner(
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
            let (planner, plannerStartOfDay) = getEarliestPlanner(
                for: event.date,
                settings: settings
            )
        else {
            // Event does not belong to any planners. Use its actual date as the sortDate.
            return event.date
        }

        let sortedStorageEventsWithoutEvent = getSortedStorageEvents(
            for: plannerStartOfDay
        )
        .filter { $0.stableId != event.stableId }

        return generateSortDate(
            startOfDay: plannerStartOfDay,
            index: 0,
            events: sortedStorageEventsWithoutEvent
        )
    }

    @MainActor
    private func getUpperSortDate(for plannerStartOfDay: DateInRegion) -> Date {
        let storageEvents = getSortedStorageEvents(for: plannerStartOfDay)
        return generateSortDate(
            startOfDay: plannerStartOfDay,
            index: 0,
            events: storageEvents
        )
    }

    @MainActor
    private func createCalendarPlannerEvent(
        for calendarEvent: EKEvent,
        in plannerStartOfDay: DateInRegion?
    ) {

        let sortDate = {
            if let plannerStartOfDay {
                return self.getUpperSortDate(for: plannerStartOfDay)
            }
            return calendarEvent.startDate
        }()

        let event = PlannerEvent(
            date: calendarEvent.startDate,
            sortDate: sortDate,
            calendarEvent: calendarEvent
        )

        insert(event)

        // Note: Don't save the context. This function is part of a larger pipeline.
    }

    @MainActor
    private func getEarliestPlanner(
        for date: Date,
        settings: PlannerSettings
    ) -> (planner: Planner, plannerStartOfDay: DateInRegion)? {

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
                    "ERROR getValidPlanner: Could not build plannerStartOfDay from \(planner.datestamp)"
                )
                continue
            }

            if date.belongsTo(plannerStartOfDay) {
                return (planner: planner, plannerStartOfDay: plannerStartOfDay)
            }
        }

        // Date does not belong to any planner.
        return nil
    }

    @MainActor
    private func insertEventIfNeeded(_ event: PlannerEvent) {
        guard event.modelContext == nil else { return }
        insert(event)
    }

}
