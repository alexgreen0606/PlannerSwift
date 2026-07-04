//
//  handleCalendarEventChange.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func handleCalendarEventChange(
        _ ekEvent: EKEvent?,
        sourcePlannerEvent: PlannerEvent?,
        sourcePlanner: Planner?,
        plannerService: PlannerService,
        settings: Settings
    ) -> /// The datestamps the event is now in.
        Set<String>
    {
        let sourceWasRecurringEvent =
            sourcePlannerEvent?.eKEventContext?.ekEvent?.hasRecurrenceRules
            == true
        let finalIsRecurringEvent = ekEvent?.hasRecurrenceRules == true

        if let sourcePlannerEvent {
            // MARK: A planner event already exists. Sync it with the updated calendar event.

            // MARK: Mark routine event records as variants.
            sourcePlannerEvent.routineEventRecordContext?.isVariant = true

            guard let ekEvent else {
                // MARK: The calendar event was deleted. Remove the storage record.

                delete(sourcePlannerEvent)
                return []
            }

            // MARK: Sync the storage record with the calendar event.

            sourcePlannerEvent.syncWithEkEvent(ekEvent)

            return ensureValidSortDate(
                for: sourcePlannerEvent,
                sourceDatestamp: sourcePlanner?.datestamp,
                settings: settings
            )

        } else if let ekEvent {
            // MARK: A planner event doesn't exist. Create one for the calendar event.

            let sortedStartsOfDays = getSortedPlannerStartOfDays(
                for: ekEvent.startDate,
                endTime: ekEvent.endDate,
                settings: settings
            )

            if let destinationStartOfDay = sortedStartsOfDays.first {
                createPlannerEvent(
                    for: ekEvent,
                    on: destinationStartOfDay
                )
            }

            return Set(sortedStartsOfDays.map(\.datestamp))
        }

        // MARK: Re-sync calendar events if source or final event is recurring.
        if sourceWasRecurringEvent || finalIsRecurringEvent {
            DispatchQueue.main.async(
                execute: plannerService.syncVisiblePlannersCalendar
            )
        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return []
    }
    
    // MARK: - Helper Function

    @MainActor
    private func createPlannerEvent(
        for ekEvent: EKEvent,
        on startOfDay: DateInRegion?
    ) {
        let sortDate = {
            guard !ekEvent.isAllDay, let startOfDay else {
                return ekEvent.startDate ?? Date.now
            }

            // Event has a target planner. Add it to the top of the list.
            return getUpperSortDate(for: startOfDay)
        }()

        insert(
            PlannerEvent(
                ekEvent: ekEvent,
                sortDate: sortDate
            )
        )

        // Note: Don't save the context.
        // This is only ever called as part of a larger pipeline.
    }
}
