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

    @MainActor
    func createEvent(
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
            events: events,
            settings: settings
        )

        let newEvent = PlannerEvent(
            date: startOfDay.date,
            sortDate: sortDate,
            calendarEvent: nil,
        )

        insert(newEvent)

        Task { @MainActor in
            do {
                try self.save()
            } catch {
                print("ERROR plannerEvent.createEvent: \(error)")
            }
        }

        return newEvent.stableId
    }

    @MainActor
    func getStorageEvents(
        for startOfDay: DateInRegion
    ) -> [PlannerEvent] {

        let startOfNextDay = (startOfDay + 1.days)

        let descriptor = FetchDescriptor<PlannerEvent>(
            predicate: #Predicate {
                $0.date >= startOfDay.date && $0.date < startOfNextDay.date
            }
        )

        do {
            return try fetch(descriptor)
        } catch {
            assertionFailure(
                "ERROR plannerEvent.getEvents: \(error)"
            )
        }

        return []

    }

    @MainActor
    func moveEvent(
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
                "ERROR: plannerEvent.moveEvent: \(error)"
            )
        }
    }

    @MainActor
    func handleTitleChange(
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
                "ERROR: plannerEvent.handleTitleChange: \(error)"
            )
        }
    }

    @MainActor
    func shiftPlannerEvents(
        _ events: [PlannerEvent],
        days: DateComponents,
        datestamp: String,
        settings: PlannerSettings,
        eventStore: EKEventStore,
        loadCalendarEvents: (
            _ planner: Planner,
            _ startOfDay: DateInRegion,
            _ hiddenCalendarIds: Set<String>
        ) -> PlannerCalendarData
    ) {

        let sortedEvents = events.sorted { $0.sortDate > $1.sortDate }
        
        let planner = loadPlanner(for: datestamp)
        
        let plannerStartOfDay = planner.datestamp.startOfDay(in: planner.region(settings: settings))

        for event in sortedEvents {
            
            if !event.hasTime {
                guard let plannerStartOfDay else {
                    assertionFailure("ERROR plannerEvent.shiftPlannerEvents: Could not build plannerStartOfDay from \(datestamp)")
                    continue
                }
                // Untimed events MUST have their date set to the planner's startOfDay.
                event.date = plannerStartOfDay.date
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
                    print("ERROR plannerEvent.shiftPlannerEvents: \(error)")
                    continue
                }

                let newSortDate = getTransferedEventSortDate(
                    date: calEvent.startDate,
                    settings: settings,
                    loadCalendarEvents: loadCalendarEvents
                )

                settings.calendarSortDateMap[
                    calEvent.calendarItemExternalIdentifier
                ] = newSortDate

                continue
            }

            event.sortDate = getTransferedEventSortDate(
                date: event.date,
                settings: settings,
                loadCalendarEvents: loadCalendarEvents
            )
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.shiftPlannerEvents: \(error)"
            )
        }
    }

    // Places the event at the top of its earliest possible planner.
    @MainActor
    private func getTransferedEventSortDate(
        date: Date,
        settings: PlannerSettings,
        loadCalendarEvents: (
            _ planner: Planner,
            _ startOfDay: DateInRegion,
            _ hiddenCalendarIds: Set<String>
        ) -> PlannerCalendarData
    ) -> Date {

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
                    "ERROR plannerEvent.getTransferedEventSortDate: Could not build plannerStartOfDay from \(planner.datestamp)"
                )
                continue
            }

            if !date.belongsTo(plannerStartOfDay) {
                print("debug | Event doesnt exist in \(datestamp)")
                continue
            }

            // Note: This WILL contain the event. This is fine.
            let plannerEvents = loadAllSortedPlannerEvents(
                for: planner,
                startOfDay: plannerStartOfDay,
                settings: settings,
                loadCalendarEvents: loadCalendarEvents
            )

            print(
                "debug | Placing event at top of \(plannerEvents.count) existing events"
            )

            return generateSortDate(
                startOfDay: plannerStartOfDay,
                index: 0,
                events: plannerEvents,
                settings: settings
            )
        }

        print("debug | Event doesnt exist in any planners.")

        // Event does not belong to any planners. Use its actual date as the sortDate.
        return date
    }

    @MainActor
    func deletePlannerEvents(
        _ events: [PlannerEvent]
    ) {

        for event in events {
            delete(event)
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete plan: \(error)"
            )
        }
    }

    @MainActor
    func deleteCheckedPlans(
        from plans: [PlannerEvent]
    ) {

        for event in plans {
            if event.isChecked {
                print("Deleting checked event: \(event.stableId)")
                delete(event)
            }
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to delete checked plans: \(error)"
            )
        }
    }

    @MainActor
    func saveEventFormChanges(
        _ draftPlannerEvent: DraftPlannerEvent,
        initialPlannerEvent: PlannerEvent?,
        initialCalendarEvent: EKEvent?
    ) {

        if draftPlannerEvent.hasTime && draftPlannerEvent.location == nil {
            assertionFailure(
                "ERROR plannerEvent.saveEventFormChanges(PlannerEvent): Draft event must have a location assigned if it has a time."
            )
        }

        if let initialPlannerEvent {

            // Reuse the existing planner event.

            initialPlannerEvent.title = draftPlannerEvent.title
            initialPlannerEvent.date = draftPlannerEvent.date
            initialPlannerEvent.hasTime = draftPlannerEvent.hasTime
            initialPlannerEvent.calendarEvent = nil
            initialPlannerEvent.location = draftPlannerEvent.location

            // Insert the event if it was previously transient.
            insertEventIfNeeded(initialPlannerEvent)

        } else {

            // Save the draft planner event to the context.

            let newEvent = PlannerEvent(
                date: draftPlannerEvent.date,
                sortDate: draftPlannerEvent.date
            )

            newEvent.title = draftPlannerEvent.title
            newEvent.date = draftPlannerEvent.date
            newEvent.hasTime = draftPlannerEvent.hasTime
            newEvent.calendarEvent = nil
            newEvent.location = draftPlannerEvent.location

            // TODO: add event to top of planner

            insert(newEvent)

        }

        // Note: Saving the context here will delete the location. Allow the model context to auto-save as needed.

    }

    @MainActor
    func saveEventFormChanges(
        _ calendarEvent: EKEvent?,
        initialPlannerEvent: PlannerEvent?,
        settings: PlannerSettings
    ) {
        if let initialPlannerEvent {

            if let calendarEvent {

                // Event was not deleted. Use the original planner event's sort date for the new event.
                settings.calendarSortDateMap[
                    calendarEvent.calendarItemExternalIdentifier
                ] = initialPlannerEvent.sortDate

            }

            // TODO: why is this needed?
            Task { @MainActor in

                self.delete(initialPlannerEvent)

                do {
                    try save()
                } catch {
                    assertionFailure(
                        "ERROR plannerEvent.saveEventFormChanges(EKEvent): \(error)"
                    )
                }

            }
        }
    }

    // MARK: - Helper Functions

    private func insertEventIfNeeded(_ event: PlannerEvent) {
        let id = event.persistentModelID

        if self.registeredModel(for: id) as PlannerEvent? != nil {
            return
        }

        insert(event)
    }

}
