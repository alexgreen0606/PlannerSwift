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
                sortDate: draftPlannerEvent.date
            )

        event.title = draftPlannerEvent.title.trimmed
        event.location = draftPlannerEvent.location

        event.time = draftPlannerEvent.hasTime ? draftPlannerEvent.date : nil
        event.datestamp = destinationDatestamp

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
