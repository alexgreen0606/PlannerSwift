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
            date: sortDate,
            calendarEvent: nil,
            sortIndex: 0
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
    func shiftPlannerEvents(
        _ events: [PlannerEvent],
        days: DateComponents,
        settings: PlannerSettings,
        eventStore: EKEventStore
    ) {

        for event in events {
            event.date = event.date + days
            event.sortDate = event.sortDate + days
            
            if let calEvent = event.calendarEvent {
                guard calEvent.calendar.allowsContentModifications else {
                    print(
                        "Calendar event is read-only. Skipping event: \(event.title)"
                    )
                    continue
                }
                
                settings.calendarSortDateMap[calEvent.calendarItemExternalIdentifier] = event.sortDate

                // Shift start and end dates
                calEvent.startDate = calEvent.startDate + days
                calEvent.endDate = calEvent.endDate + days

                do {
                    try eventStore.save(calEvent, span: .thisEvent, commit: true)
                } catch {
                    print("ERROR plannerEvent.shiftPlannerEvents: \(error)")
                }
                
            }

            // TODO 2: place the sortDate at the back of the planner
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR plannerEvent.shiftPlannerEvents: \(error)"
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
            assertionFailure("ERROR plannerEvent.saveEventFormChanges(PlannerEvent): Draft event must have a location assigned if it has a time.")
        }

        if let initialPlannerEvent {

            // Reuse the existing planner event.

            initialPlannerEvent.title = draftPlannerEvent.title
            initialPlannerEvent.date = draftPlannerEvent.date
            initialPlannerEvent.hasTime = draftPlannerEvent.hasTime
            initialPlannerEvent.calendarEvent = nil
            initialPlannerEvent.location = draftPlannerEvent.location

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

            // TODO: add event to bottom of planner

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

}
