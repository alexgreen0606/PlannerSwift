//
//  syncCalendar.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate

// Clean

extension ModelContext {

    @MainActor
    func syncCalendar(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        hiddenCalendarIds: Set<String>,
        ekEventStore: EKEventStore
    ) -> CalendarDayData {

        var existingCalendarStorageEvents = Dictionary(
            uniqueKeysWithValues: storageEvents.compactMap { event in
                event.calendarItemExternalIdentifier.map { ($0, event) }
            }
        )

        // ------------------------------------------------------------------
        // Load in the day's events, sorted reverse-chronological.
        // ------------------------------------------------------------------

        let nextDay = plannerDay + 1.days
        let calendarEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: plannerDay.date,
                end: nextDay.date,
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
        var birthdayEvents: [String: EKEvent] = [:]
        var occurrenceEvents: [String: EKEvent] = [:]
        var regularEvents: [String: EKEvent] = [:]

        for calendarEvent in calendarEvents {

            // Skip events from calendars that are excluded in the app settings.
            if hiddenCalendarIds.contains(
                calendarEvent.calendar.calendarIdentifier
            ) {
                continue
            }

            if calendarEvent.calendar.type == .birthday,
                let contactId = calendarEvent.birthdayContactIdentifier
            {
                // Collect birthday events.
                birthdayEvents[contactId] = calendarEvent
                continue
            }

            if let occurrenceId = calendarEvent.occurrenceId {
                // Collect recurring events.
                occurrenceEvents[occurrenceId] = calendarEvent
            } else {
                // Collect regular timed events.
                regularEvents[calendarEvent.calendarItemExternalIdentifier] =
                    calendarEvent
            }

            if calendarEvent.isAllDay {

                // Collect all-day events as planner chips.
                plannerChipEvents.append(calendarEvent)

            } else {

                if calendarEvent.spansOutsidePlannerDay(
                    plannerDay: plannerDay
                ) {
                    // Collect events that span outside this day as planner chips.
                    plannerChipEvents.append(calendarEvent)
                }

                // Display events as planner events if they start during this day.
                if calendarEvent.startDate.belongsTo(plannerDay) {
                    self.upsertCalendarEventToPlanner(
                        calendarEvent,
                        existingCalendarEvents: &existingCalendarStorageEvents,
                        plannerDay: plannerDay
                    )
                }

            }
        }

        // ------------------------------------------------------------------
        // Clean up any remaining storage events.
        // Remove calendar records that no longer exist,
        // otherwise move them to their new planners.
        // ------------------------------------------------------------------

        self.updateStaleStorageEvents(
            Array(existingCalendarStorageEvents.values),
            ekEventStore: ekEventStore
        )

        // ------------------------------------------------------------------
        // Load in the contacts for all birthday events.
        // ------------------------------------------------------------------

        var birthdays: [Birthday] = []

        let store = CNContactStore()
        do {
            let contacts = try store.unifiedContacts(
                matching: CNContact.predicateForContacts(
                    withIdentifiers: Array(birthdayEvents.keys)
                ),
                keysToFetch: [
                    CNContactViewController.descriptorForRequiredKeys()
                ] as [CNKeyDescriptor]
            )

            for contact in contacts {
                guard let event = birthdayEvents[contact.identifier]
                else { continue }

                birthdays.append(Birthday(contact: contact, event: event))
            }

        } catch {
            assertionFailure("ERROR syncCalendar: \(error)")
        }

        self.safeSave("syncCalendar")

        return CalendarDayData(
            plannerChipEvents: plannerChipEvents,
            birthdays: birthdays,
            occurrenceEvents: occurrenceEvents,
            regularEvents: regularEvents
        )
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
            // Event doesn't exist in this planner. Add it.
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

    // TODO: why not private?
    @MainActor
    func addCalendarEventToPlanner(
        // Guaranteed to not have a storage event in the planner.
        _ calendarEvent: EKEvent,
        plannerDay: DateInRegion
    ) {

        if calendarEvent.occurrenceId != nil {
            // Special case: Automatically create a new record if this is a recurring event occurrence.
            self.createPlannerEvent(
                for: calendarEvent,
                in: plannerDay
            )
            return
        }

        guard
            let calendarItemExternalIdentifier = calendarEvent
                .calendarItemExternalIdentifier
        else {
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
                self.createPlannerEvent(
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
            self.createPlannerEvent(
                for: calendarEvent,
                in: plannerDay
            )
        }

        // Note: Don't save the context.
        // This is part of a larger pipeline.
    }

    @MainActor
    private func updateStaleStorageEvents(
        // Storage events that no longer exist in their calendar day
        _ staleStorageEvents: [PlannerEvent],
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
