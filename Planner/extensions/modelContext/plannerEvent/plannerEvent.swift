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
            plannerDay: startOfDay,
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
    func cancelPlannerEvent(_ event: PlannerEvent) {
        event.isCanceled = true
        self.safeSave("plannerEvent.cancelPlannerEvent")
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
        let checked = events.filter { $0.isCompleted }
        self.deletePlannerEvents(checked, ekEventStore: ekEventStore)
        self.safeSave("plannerEvent.deleteCheckedStorageEvents")
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
            plannerDay: plannerDay,
            index: to,
            sortedEvents: sortedEvents
        )

        self.safeSave("plannerEvent.movePlannerEvent")
    }

    @MainActor
    func handlePlannerEventTitleChange(
        _ event: PlannerEvent,
        plannerDay: DateInRegion,
        eventKitStore: EKEventStore,
        defaultLocation: Location?
    ) {
        event.handleTitleChange(
            startOfDay: plannerDay,
            eventKitStore: eventKitStore,
            defaultLocation: defaultLocation
        )

        self.safeSave("plannerEvent.handlePlannerEventTitleChange")
    }

    @MainActor
    func transferPlannerEvents(
        _ events: [PlannerEvent],
        days: DateComponents,
        sourceDay: DateInRegion,
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
                "ERROR plannerEvent.transferPlannerEvents: Could not build plannerDay from \(targetDatestamp)"
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

            updateSortDate(
                for: event,
                settings: settings,
                sourceDay: sourceDay
            )
        }

        self.safeSave("plannerEvent.transferPlannerEvents")
    }

    @MainActor
    func handlePlannerEventChange(
        _ draftPlannerEvent: DraftPlannerEvent,
        sourceDay: DateInRegion?,
        targetDatestamp: String,
        settings: PlannerSettings,
        ekEventStore: EKEventStore,
        sourcePlannerEvent: PlannerEvent?,
        sourceCalendarEvent: EKEvent?
    ) -> DateInRegion? {

        let event =
            sourcePlannerEvent
            ?? PlannerEvent(
                date: draftPlannerEvent.date,
                sortDate: draftPlannerEvent.date
            )

        event.title = draftPlannerEvent.title
        event.hasTime = draftPlannerEvent.hasTime
        event.calendarEvent = nil
        event.calendarItemExternalIdentifier = nil
        event.location = draftPlannerEvent.location

        if !event.hasTime {
            let targetPlanner = loadPlanner(
                for: targetDatestamp
            )
            guard
                let destinationDay = targetPlanner.datestamp
                    .startOfDay(in: targetPlanner.region(settings: settings))
            else {
                assertionFailure(
                    "ERROR: Could not create plannerDay from \(targetPlanner.datestamp)"
                )
                return sourceDay
            }

            // Untimed events MUST have their date set to the planner's startOfDay.
            event.date = destinationDay.date

        } else {
            event.date = draftPlannerEvent.date
        }

        let destinationDay = updateSortDate(
            for: event,
            settings: settings,
            sourceDay: sourceDay
        )

        self.insertEventIfNeeded(event)

        // Delete the old calendar event.
        if let sourceCalendarEvent {
            let _ = ekEventStore.deleteEvent(sourceCalendarEvent)
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDay
    }

    @MainActor
    func updateSortDate(
        for event: PlannerEvent,
        settings: PlannerSettings,
        sourceDay: DateInRegion? = nil
    ) -> DateInRegion? {

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

        // Priority 1: Reuse the event's existing position if it has not moved planners.
        if let sourceDay,
            plannerDay.datestamp == sourceDay.datestamp
        {
            return sourceDay
        }

        let sortedStorageEvents = self.getSortedStorageEvents(
            for: plannerDay
        )

        // Place the event at the start of its new planner.
        event.sortDate = generateSortDate(
            plannerDay: plannerDay,
            index: 0,
            sortedEvents: sortedStorageEvents
        )

        return plannerDay
    }

    @MainActor
    func getUpperSortDate(for plannerDay: DateInRegion) -> Date {
        let storageEvents = getSortedStorageEvents(for: plannerDay)
        return generateSortDate(
            plannerDay: plannerDay,
            index: 0,
            sortedEvents: storageEvents
        )
    }

    @MainActor
    func getEarliestPlannerDay(
        for date: Date,
        settings: PlannerSettings,
        requireExactMatch: Bool = false
    ) -> DateInRegion? {

        let chronologicalPossibleDatestamps =
            getChronologicalPossibleDatestamps(for: date)

        for datestamp in chronologicalPossibleDatestamps {

            let planner = loadPlanner(for: datestamp)
            guard
                let plannerDay = planner.datestamp.startOfDay(
                    in: planner.region(settings: settings)
                )
            else {
                assertionFailure(
                    "ERROR plannerEvent.getEarliestPlannerStartOfDay: Could not build plannerDay from \(planner.datestamp)"
                )
                continue
            }

            if requireExactMatch {
                if date == plannerDay.date {
                    return plannerDay
                }
            } else if date.belongsTo(plannerDay) {
                return plannerDay
            }
        }

        // Date does not belong to any planner.
        return nil
    }

    // MARK: - Helper Functions

    @MainActor
    private func getSortedStorageEvents(for plannerDay: DateInRegion)
        -> [PlannerEvent]
    {
        let startOfNextDay = (plannerDay + 1.days)

        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate {
                        $0.date >= plannerDay.date
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
