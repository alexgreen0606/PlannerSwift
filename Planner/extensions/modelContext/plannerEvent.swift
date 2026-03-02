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
        
        print("debug | EventCount: \(events.count)")

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
            events: events,
            settings: settings
        )

        let newEvent = PlannerEvent(
            date: startOfDay.date,
            sortDate: sortDate,
            calendarEvent: nil,
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
        events: [PlannerEvent],
        settings: PlannerSettings
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
            events: eventsWithoutEvent,
            settings: settings
        )

        // Handle calendar event position changes.
        if let calEvent = movedEvent.calendarEvent {
            settings.calendarSortDateMap[
                calEvent.calendarItemExternalIdentifier
            ] = movedEvent.sortDate
        }

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
        eventStore: EKEventStore,
        loadCalendarData: @escaping PlannerDataLoader
    ) {

        // Used for untimed events only.
        let targetPlanner = loadPlanner(for: targetDatestamp)
        let targetPlannerStartOfDay = targetPlanner.datestamp.startOfDay(
            in: targetPlanner.region(settings: settings)
        )

        let sortedEvents = events.sorted { $0.sortDate > $1.sortDate }

        for event in sortedEvents {

            if !event.hasTime {
                guard let targetPlannerStartOfDay else {
                    assertionFailure(
                        "ERROR plannerEvent.transferPlannerEvents: Could not build plannerStartOfDay from \(targetDatestamp)"
                    )
                    continue
                }

                // Untimed events MUST have their date set to the planner's startOfDay.
                event.date = targetPlannerStartOfDay.date

            } else {
                event.date = event.date + days
            }

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

                let newSortDate = getUpperSortDate(
                    for: event,
                    settings: settings,
                    previousPlannerDatestamp: previousDatestamp,
                    loadCalendarData: loadCalendarData
                )

                settings.calendarSortDateMap[
                    calEvent.calendarItemExternalIdentifier
                ] = newSortDate

                continue
            }

            event.sortDate = getUpperSortDate(
                for: event,
                settings: settings,
                previousPlannerDatestamp: previousDatestamp,
                loadCalendarData: loadCalendarData
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
        initialPlannerEvent: PlannerEvent?,
        initialCalendarEvent: EKEvent?,
        loadCalendarData: @escaping PlannerDataLoader
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

        event.title = draftPlannerEvent.title
        event.date = draftPlannerEvent.date
        event.hasTime = draftPlannerEvent.hasTime
        event.calendarEvent = nil
        event.location = draftPlannerEvent.location

        // Untimed events must have their date set to the start date of their planner.
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

            event.date = targetPlannerStartOfDay.date
        }

        let newSortDate = getUpperSortDate(
            for: event,
            settings: settings,
            previousPlannerDatestamp: previousDatestamp,
            loadCalendarData: loadCalendarData
        )

        event.sortDate = newSortDate

        insertEventIfNeeded(event)

        // Note: Saving the context here will delete the location. Allow the model context to auto-save when needed.

    }

    @MainActor
    func handleCalendarEventChange(
        _ calendarEvent: EKEvent?,
        initialPlannerEvent: PlannerEvent?,
        settings: PlannerSettings
    ) {
        if let initialPlannerEvent {

            if let calendarEvent {

                // Use the original planner event's sort date for the new event.
                settings.calendarSortDateMap[
                    calendarEvent.calendarItemExternalIdentifier
                ] = initialPlannerEvent.sortDate

            }

            self.delete(initialPlannerEvent)

            do {
                try save()
            } catch {
                assertionFailure(
                    "ERROR plannerEvent.handleCalendarEventChange: \(error)"
                )
            }

        }
    }

    // MARK: - Helper Functions

    @MainActor
    private func getAllSortedPlannerEvents(
        for planner: Planner,
        startOfDay: DateInRegion,
        settings: PlannerSettings,
        loadCalendarData: @escaping PlannerDataLoader
    ) -> [PlannerEvent] {
        let storageEvents = getStorageEvents(for: startOfDay)

        let calendarData = loadCalendarData(
            planner,
            true,
            startOfDay,
            settings.hiddenCalendarIds
        )

        let calendarPlannerEvents = buildCalendarPlannerEvents(
            calendarEvents: calendarData.timedEvents,
            storageEvents: storageEvents,
            startOfDay: startOfDay,
            settings: settings
        )

        return (storageEvents + calendarPlannerEvents).sorted {
            $0.sortDate < $1.sortDate
        }
    }

    @MainActor
    private func getStorageEvents(for plannerStartOfDay: DateInRegion)
        -> [PlannerEvent]
    {

        let startOfNextDay = (plannerStartOfDay + 1.days)

        let descriptor = FetchDescriptor<PlannerEvent>(
            predicate: #Predicate {
                $0.date >= plannerStartOfDay.date
                    && $0.date < startOfNextDay.date
            }
        )

        do {
            return try fetch(descriptor)
        } catch {
            assertionFailure(
                "ERROR plannerEvent.getStorageEvents: \(error)"
            )
        }

        return []
    }

    @MainActor
    private func getUpperSortDate(
        for event: PlannerEvent,
        settings: PlannerSettings,
        previousPlannerDatestamp: String?,
        loadCalendarData: @escaping PlannerDataLoader
    ) -> Date {

        let chronologicalPossibleDatestamps =
            getChronologicalPossibleDatestamps(for: event.date)
        
        for datestamp in chronologicalPossibleDatestamps {

            // Event has not moved from its current planner. Keep its existing position.
            if datestamp == previousPlannerDatestamp {
                return event.sortDate
            }

            let planner = loadPlanner(for: datestamp)

            guard
                let plannerStartOfDay = planner.datestamp.startOfDay(
                    in: planner.region(settings: settings)
                )
            else {
                assertionFailure(
                    "ERROR plannerEvent.getTransferedEventSortDate: Could not build plannerStartOfDay from \(planner.datestamp)"
                )
                continue
            }

            if !event.date.belongsTo(plannerStartOfDay) {
                continue
            }

            let plannerEvents = getAllSortedPlannerEvents(
                for: planner,
                startOfDay: plannerStartOfDay,
                settings: settings,
                loadCalendarData: loadCalendarData
            )
            // Filter out the event.
            .filter { other in
                if let calEvent = event.calendarEvent {
                    return other.calendarEvent?.calendarItemExternalIdentifier
                        != calEvent.calendarItemExternalIdentifier
                } else {
                    return other.stableId != event.stableId
                }
            }
            
            return generateSortDate(
                startOfDay: plannerStartOfDay,
                index: 0,
                events: plannerEvents,
                settings: settings
            )
        }

        // Event does not belong to any planners. Use its actual date as the sortDate.
        return event.date
    }

    @MainActor
    private func insertEventIfNeeded(_ event: PlannerEvent) {
        guard event.modelContext == nil else { return }
        insert(event)
    }

}
