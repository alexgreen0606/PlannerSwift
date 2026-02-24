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
        near baseId: PersistentIdentifier?,
        offset: Int,
        in events: [PlannerEvent],
        startOfDay: DateInRegion,
        settings: PlannerSettings
    ) {

        guard
            let baseIndex = baseId == nil
                ? 0
                : events.firstIndex(where: {
                    $0.id == baseId
                })
        else {
            assertionFailure(
                "ERROR plannerEvent.createEvent: Failed to get a base index for the new event."
            )
            return
        }

        let finalIndex = baseIndex + offset

        // Don't create the new event if it is next to an empty event.

        let upperEvent = finalIndex > 0 ? events[finalIndex - 1] : nil
        if let upperEvent, upperEvent.title.isEmpty {
            return
        }

        let lowerEvent =
            finalIndex < events.count
            ? events[finalIndex] : nil
        if let lowerEvent, lowerEvent.title.isEmpty {
            return
        }

        let sortDate = generateSortDate(
            startOfDay: startOfDay,
            index: finalIndex,
            events: events,
            settings: settings
        )

        let newEvent = PlannerEvent(
            date: sortDate,
            calendarEvent: nil,
            sortIndex: 0
        )

        insert(newEvent)

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.createEvent: \(error)"
            )
        }
    }

    @MainActor
    func getEvents(
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
            $0.id != movedEvent.id
        }
        let newSortDate = generateSortDate(
            startOfDay: startOfDay,
            index: to,
            events: eventsWithoutEvent,
            settings: settings
        )
        movedEvent.sortDate = newSortDate

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
        eventKitStore: EKEventStore
    ) {

        event.handleTitleChange(
            startOfDay: startOfDay,
            eventKitStore: eventKitStore
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
    func transferPlannerEvents(
        _ events: [PlannerEvent],
        to startOfDay: DateInRegion,
        preserveTimeOfDay: Bool = true
    ) {

        let targetRegion = startOfDay.region

        for event in events {
            if !event.hasTime {
                event.date = startOfDay.date
            } else {

                // TODO: shift date and preserve time of day if needed.

                //                if let newDate = event.date.shiftDate(to: self.datestamp, in: region) {
                //                    print("P: \(event.date) -> \(newDate)")
                //                    event.date = newDate
                //                } else {
                //                    assertionFailure(
                //                        "ERROR PlannerEventExtension.inheritEvents: Failed to shift event to new date."
                //                    )
                //                    // TODO: still need to shift event somehow
                //                    event.untimed = true
                //                }
            }
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
                print("Deleting checked event: \(event.id)")
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
    func savePlannerEventChanges(
        _ draftPlannerEvent: DraftPlannerEvent,
        initialPlannerEvent: PlannerEvent?,
        initialCalendarEvent: EKEvent?
    ) {

        if let initialPlannerEvent {

            // Reuse the existing planner event.

            initialPlannerEvent.title = draftPlannerEvent.title
            initialPlannerEvent.date = draftPlannerEvent.date
            initialPlannerEvent.hasTime = draftPlannerEvent.hasTime
            initialPlannerEvent.calendarEvent = nil
            initialPlannerEvent.location = draftPlannerEvent.location
            initialPlannerEvent.locationSource = draftPlannerEvent.locationSource


        } else {

            // Save the draft planner event to the context.

            let newEvent = PlannerEvent(
                date: draftPlannerEvent.date,
                sortIndex: 0
            )
            
            newEvent.title = draftPlannerEvent.title
            newEvent.date = draftPlannerEvent.date
            newEvent.hasTime = draftPlannerEvent.hasTime
            newEvent.calendarEvent = nil
            newEvent.location = draftPlannerEvent.location
            newEvent.locationSource = draftPlannerEvent.locationSource

            // TODO: add event to bottom of planner

            insert(newEvent)

        }

        // Note: Saving the context here will delete the location. Allow the model context to auto-save as needed.

    }

    @MainActor
    func savePlannerEventChanges(
        _ calendarEvent: EKEvent?,
        initialPlannerEvent: PlannerEvent?,
        settings: PlannerSettings
    ) {
        if let initialPlannerEvent {

            if let calendarEvent {

                // Event was not deleted. Use the original planner event's sort date for the new event.
                settings.calendarSortDateMap[
                    calendarEvent.calendarItemExternalIdentifier
                ] =
                    initialPlannerEvent.sortDate

            }

            Task { @MainActor in
                self.delete(initialPlannerEvent)
            }

            do {
                try save()
            } catch {
                assertionFailure(
                    "ERROR plannerEvent.savePlannerEventChanges(EKEvent): \(error)"
                )
            }
        }
    }

}
