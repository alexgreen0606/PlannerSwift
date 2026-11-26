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
        todayService: TodayService,
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

        // MARK: Save draft to planner event.

        event.title = draftPlannerEvent.title.trimmed
        event.notes = draftPlannerEvent.notes.trimmed

        if draftPlannerEvent.hasTime {
            event.time = draftPlannerEvent.date
            event.datestamp = nil
        } else {
            event.datestamp = destinationDatestamp
            event.time = nil
        }

        event.location = draftPlannerEvent.location
        event.isFlagged = draftPlannerEvent.isFlagged

        // MARK: Delete stale calendar context if one exists.

        safeDelete(event.eKEventContext, skipSave: true)
        event.eKEventContext = nil

        // MARK: Place the event at the top of its planner if it has moved days.

        let destinationDatestamps = ensureValidPlannerEventPosition(
            for: event,
            sourceDatestamp: sourcePlanner?.datestamp,
            todayStartOfDay: todayService.todayStartOfDay,
            settings: settings
        )

        // MARK: Update routine event variance.
        event.updateRoutineVariance(
            in: timeZone,
            settings: settings
        )

        // MARK: Sync the draft of the event.
        event.syncDraft()

        // MARK: Persist changes into the model context.
        insertIfNeeded(event)

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return destinationDatestamps
    }
}
