//
//  updatePlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 5/31/26.
//

import EventKit
import SwiftData

extension ModelContext {
    @MainActor
    func updatePlannerEvent(
        _ sourcePlannerEvent: PlannerEvent?,
        with draftPlannerEvent: DraftPlannerEvent,
        destinationDatestamp: String,
        sourcePlanner: Planner?,
        timeZone: TimeZone,
        plannerService: PlannerService,
        ekEventStore: EKEventStore,
        settings: Settings,
    ) -> /// The datestamps the event is now in.
        Set<String>
    {
        let event =
            sourcePlannerEvent
            ?? PlannerEvent(
                datestamp: destinationDatestamp,
                sortDate: draftPlannerEvent.date
            )

        let staleEkEvent = sourcePlannerEvent?.eKEventContext?.ekEvent
        let eventWasRecurring = staleEkEvent?.hasRecurrenceRules == true

        // MARK: Save draft to planner event.

        event.title = draftPlannerEvent.title.trimmed

        if draftPlannerEvent.hasTime {
            event.time = draftPlannerEvent.date
            event.datestamp = nil
        } else {
            event.datestamp = destinationDatestamp
            event.time = nil
        }

        event.location = draftPlannerEvent.location

        // MARK: Delete stale calendar context if one exists.

        safeDelete(event.eKEventContext, skipSave: true)
        event.eKEventContext = nil

        // MARK: Place the event at the top of its planner if it has moved days.
        let destinationDatestamps = ensureValidSortDate(
            for: event,
            sourceDatestamp: sourcePlanner?.datestamp,
            settings: settings
        )

        // MARK: Update routine event variance.
        event.updateRoutineVariance(
            in: timeZone,
            settings: settings
        )

        // MARK: Delete the old calendar event if one exists.
        // Will not delete sibling occurences, just this event.
        if let staleEkEvent {
            _ = ekEventStore.attemptDeleteEvent(staleEkEvent)
        }

        // MARK: Persist changes into the model context.
        insertIfNeeded(event)

        // MARK: Re-sync calendar events if this event was recurring.
        if eventWasRecurring {
            DispatchQueue.main.async(
                execute: plannerService.syncVisiblePlannersCalendar
            )
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDatestamps
    }
}
