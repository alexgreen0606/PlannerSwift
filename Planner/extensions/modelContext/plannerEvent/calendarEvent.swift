//
//  calendarEvent.swift
//  Planner
//
//  Created by Alex Green on 3/8/26.
//

import EventKit
import SwiftData
import SwiftDate

// Clean

extension ModelContext {

    @MainActor
    func deleteCalendarEvent(_ event: PlannerEvent, ekEventStore: EKEventStore)
    {
        guard let calEvent = event.calendarEvent else {
            return
        }

        if ekEventStore.deleteEvent(calEvent) {
            self.delete(event)
        }

        self.safeSave("calendarEvent.deleteCalendarEvent")
    }

    @MainActor
    func syncCalendarEvents(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        hiddenCalendarIds: Set<String>,
        ekEventStore: EKEventStore
    ) -> CalendarSearchResults {
        let startOfNextPlannerDay = plannerDay + 1.days

        // Existing events in storage for this planner range.
        var existingCalendarStorageEvents = Dictionary(
            uniqueKeysWithValues: storageEvents.compactMap { event in
                event.calendarItemExternalIdentifier.map { ($0, event) }
            }
        )

        // ------------------------------------------------------------------
        // Load in the day's events, sorted reverse-chronological.
        // ------------------------------------------------------------------

        let events = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: plannerDay.date,
                end: startOfNextPlannerDay.date,
                calendars: nil
            )
        ).sorted {
            $0.startDate > $1.startDate
        }

        // ------------------------------------------------------------------
        // Loop over the calendar events, creating new storage records and
        // syncing existing ones.
        // ------------------------------------------------------------------

        var plannerChipEvents: [EKEvent] = []
        var occurrenceEvents: [String: EKEvent] = [:]
        var regularEvents: [String: EKEvent] = [:]

        for event in events {

            // Skip events from calendars that are excluded in the app settings.
            if hiddenCalendarIds.contains(event.calendar.calendarIdentifier) {
                continue
            }

            if let occurrenceId = event.occurrenceId {
                occurrenceEvents[occurrenceId] = event
            } else {
                regularEvents[event.calendarItemExternalIdentifier] = event
            }

            if event.isAllDay {

                // Event is all-day. Display it as a planner chip.
                plannerChipEvents.append(event)

            } else {

                // Display the event as a chip if it spans more than just this planner day.
                if event.spansOutsidePlannerDay(
                    plannerDay: plannerDay
                ) {
                    plannerChipEvents.append(event)
                }

                // Display the event as a planner event if it starts during this planner day.
                if event.startDate.belongsTo(plannerDay) {
                    self.upsertCalendarEventToPlanner(
                        event,
                        existingCalendarEvents: &existingCalendarStorageEvents,
                        plannerDay: plannerDay
                    )
                }

            }
        }

        // ------------------------------------------------------------------
        // Remove any extra calendar storage events that no longer exist.
        // ------------------------------------------------------------------

        self.updateStorageEvents(
            Array(existingCalendarStorageEvents.values),
            ekEventStore: ekEventStore
        )

        self.safeSave("plannerEvent.syncCalendarEvents")

        return CalendarSearchResults(
            plannerChipEvents: plannerChipEvents,
            occurrenceEvents: occurrenceEvents,
            regularEvents: regularEvents
        )
    }

    @MainActor
    func handleCalendarEventChange(
        _ calendarEvent: EKEvent?,
        sourceDay: DateInRegion?,
        sourcePlannerEvent: PlannerEvent?,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) -> DateInRegion? {

        var targetDay: DateInRegion?

        if let sourcePlannerEvent {

            // A storage record exists for this calendar event.

            guard let calendarEvent, !calendarEvent.isAllDay else {

                // The calendar event is deleted or all-day. Remove the storage record.
                self.delete(sourcePlannerEvent)
                return nil
            }

            // The calendar event is timed. Sync the storage record with the calendar event.
            sourcePlannerEvent.syncWithCalendarEvent(calendarEvent)
            targetDay = self.updateSortDate(
                for: sourcePlannerEvent,
                settings: settings,
                sourceDay: sourceDay
            )

        } else if let calendarEvent {

            targetDay = getEarliestPlannerDay(
                for: calendarEvent.startDate,
                settings: settings
            )

            self.createCalendarStorageEvent(
                for: calendarEvent,
                in: targetDay
            )

        }

        // Note: Saving the context here will delete the location.
        // Allow the context to auto-save when ready.

        return targetDay
    }

    // MARK: - Helper Functions

    @MainActor
    private func upsertCalendarEventToPlanner(
        _ calendarEvent: EKEvent,
        existingCalendarEvents: inout [String: PlannerEvent],
        plannerDay: DateInRegion
    ) {
        guard
            let storageEvent = existingCalendarEvents[
                calendarEvent.calendarItemExternalIdentifier
            ]
        else {
            // Event doesn't exist in this planner.
            self.addCalendarEventToPlanner(
                calendarEvent,
                plannerDay: plannerDay
            )
            return
        }

        // Event is already in this planner. Sync it with the calendar event.
        storageEvent.syncWithCalendarEvent(calendarEvent)
        existingCalendarEvents.removeValue(
            forKey: calendarEvent.calendarItemExternalIdentifier
        )

        // Note: Don't save the context.
        // This is part of a larger pipeline.
    }

    @MainActor
    private func addCalendarEventToPlanner(
        _ calendarEvent: EKEvent,  // Guaranteed to not have a storage event in the planner.
        plannerDay: DateInRegion
    ) {

        if calendarEvent.occurrenceId != nil {
            // Special case: Automatically create a new record if this is a recurring event occurrence.
            self.createCalendarStorageEvent(
                for: calendarEvent,
                in: plannerDay
            )
            return
        }

        guard
            let calendarItemExternalIdentifier = calendarEvent
                .calendarItemExternalIdentifier
        else {
            assertionFailure(
                "ERROR plannerEvent.addCalendarEventToPlanner: Calendar event does not have an external identifier."
            )
            return
        }

        do {

            // Search for a matching event somewhere in storage.
            let storageEvents = try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate<PlannerEvent> {
                        if let calId = $0.calendarItemExternalIdentifier {
                            return calId == calendarItemExternalIdentifier
                        } else {
                            return false
                        }
                    }
                )
            )

            guard let storageEvent = storageEvents.first else {

                // No matching storage event exists. Create a new one.
                self.createCalendarStorageEvent(
                    for: calendarEvent,
                    in: plannerDay
                )
                return
            }

            // A matching storage event exists. Sync it with the calendar event and move
            // it to the planner day.
            storageEvent.syncWithCalendarEvent(calendarEvent)
            storageEvent.sortDate = self.getUpperSortDate(
                for: plannerDay
            )

        } catch {

            // Failed to fetch a matching storage event. Create a new one.
            self.createCalendarStorageEvent(
                for: calendarEvent,
                in: plannerDay
            )
        }

        // Note: Don't save the context.
        // This is part of a larger pipeline.
    }

    @MainActor
    private func createCalendarStorageEvent(
        for calendarEvent: EKEvent,
        in plannerDay: DateInRegion?
    ) {
        if calendarEvent.isAllDay { return }

        let sortDate = {
            if let plannerDay {
                // Event has a target planner. Add it to the top of the list.
                return self.getUpperSortDate(for: plannerDay)
            }
            return calendarEvent.startDate
        }()

        insert(
            PlannerEvent(
                date: calendarEvent.startDate,
                sortDate: sortDate,
                calendarEvent: calendarEvent
            )
        )

        // Note: Don't save the context.
        // This is part of a larger pipeline.
    }

    @MainActor
    private func updateStorageEvents(
        _ staleStorageEvents: [PlannerEvent],  // Calendar storage events that no longer exist in their calendar day.
        ekEventStore: EKEventStore
    ) {
        for staleEvent in staleStorageEvents {

            guard
                let externalIdentifier = staleEvent
                    .calendarItemExternalIdentifier
            else {
                continue
            }

            guard
                let calendarEvent = ekEventStore.calendarItems(
                    withExternalIdentifier: externalIdentifier
                ).first as? EKEvent,
                calendarEvent.isAllDay == false,
                calendarEvent.occurrenceId == nil
            else {
                // The calendar event is deleted, recurring, or an all-day event.
                // Delete the storage event.
                self.delete(staleEvent)
                continue
            }

            // The event has moved to a different day. Update its storage event.
            staleEvent.syncWithCalendarEvent(calendarEvent)
        }
    }

}
