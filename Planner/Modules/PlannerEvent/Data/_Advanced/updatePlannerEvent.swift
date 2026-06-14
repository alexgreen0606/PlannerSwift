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
        sourceCalendarEvent: EKEvent?,
        sourcePlanner: Planner?,
        timeZone: TimeZone,
        ekEventStore: EKEventStore,
        settings: PlannerSettings,
    ) -> /// The datestamps the event is now in.
        Set<String>
    {
        let event =
            sourcePlannerEvent
            ?? PlannerEvent(
                datestamp: destinationDatestamp,
                sortDate: draftPlannerEvent.date
            )

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

        safeDelete(event.calendarContext, skipSave: true)
        event.calendarContext = nil

        // MARK: Place the event at the top of its planner if it has moved days.
        let destinationDatestamps = ensureValidSortDate(
            for: event,
            settings: settings,
            sourceDatestamp: sourcePlanner?.datestamp
        )

        // MARK: Create/delete routine event variant as needed.
        if let sourcePlanner {
            updatePlannerEventRoutineVariance(
                event,
                in: timeZone,
                sourcePlanner: sourcePlanner,
                staleCalendarItemExternalIdentifier: sourceCalendarEvent?
                    .calendarItemExternalIdentifier,
                settings: settings
            )
        }

        // MARK: Delete the old calendar event if one exists.
        if let sourceCalendarEvent {
            _ = ekEventStore.attemptDeleteEvent(sourceCalendarEvent)
        }

        insertIfNeeded(event)

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDatestamps
    }
}
