//
//  buildPlanner.swift
//  Planner
//
//  Created by Alex Green on 4/10/26.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate

// Clean

extension ModelContext {

    @MainActor
    func buildPlanner(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        hiddenCalendarIds: Set<String>,
        ekEventStore: EKEventStore
    ) -> CalendarDayData {

        // ------------------------------------------------------------------
        // Load in the day's existing calendar events.
        // ------------------------------------------------------------------

        let nextDay = plannerDay + 1.days
        let calendarEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: plannerDay.date,
                end: nextDay.date,
                calendars: nil
            )
        )

        var existingCalendarEvents = Dictionary(
            uniqueKeysWithValues: calendarEvents.compactMap { event in
                event.calendarItemExternalIdentifier.map { ($0, event) }
            }
        )

        // ------------------------------------------------------------------
        // Load in the day's existing routine events.
        // ------------------------------------------------------------------

        let weekday = Weekday.from(planner.datestamp.weekday)

        let routineEvents: [RoutineEvent] = {
            guard let weekday else {
                return []
            }
            return self.loadSortedRoutineEvents(for: weekday)
        }()

        var existingRoutineEvents = Dictionary(
            uniqueKeysWithValues: routineEvents.map { event in
                (event.stableId, event)
            }
        )

        // ------------------------------------------------------------------
        // Loop over the existing planner events, syncing valid calendar and
        // routine events. Delete stale events.
        // ------------------------------------------------------------------

        var plannerChipEvents: [EKEvent] = []
        var birthdayEvents: [String: EKEvent] = [:]
        var occurrenceEvents: [String: EKEvent] = [:]
        var regularEvents: [String: EKEvent] = [:]

        for plannerEvent in storageEvents {

            if let calendarEventId = plannerEvent.calendarItemExternalIdentifier
            {
                // MARK: Calendar Event

                guard
                    let calendarEvent = existingCalendarEvents[calendarEventId]
                else {
                    // Calendar event is deleted. Remove this record and continue.
                    self.delete(plannerEvent)
                    continue
                }

                existingCalendarEvents.removeValue(forKey: calendarEventId)

                guard
                    self.validateCalendarEventSynchronization(
                        calendarEvent,
                        plannerEvent: plannerEvent,
                        birthdayEvents: &birthdayEvents,
                        plannerChipEvents: &plannerChipEvents,
                        regularEvents: &regularEvents,
                        occurrenceEvents: &occurrenceEvents,
                        hiddenCalendarIds: hiddenCalendarIds,
                        plannerDay: plannerDay
                    )
                else {
                    continue
                }

                plannerEvent.syncWithCalendarEvent(calendarEvent)

            } else if let routineEventId = plannerEvent.routineEventId {
                // MARK: Routine Event

                // TODO: skip if exception

                // TODO: remove if routine events hidden

                guard
                    let routineEvent = existingRoutineEvents[routineEventId]
                else {
                    // Routine event is deleted. Remove this record and continue.
                    self.delete(plannerEvent)
                    continue
                }

                existingRoutineEvents.removeValue(forKey: routineEventId)

                plannerEvent.syncWithRoutineEvent(routineEvent, on: plannerDay)

            }
        }

        // ------------------------------------------------------------------
        // Loop over remaining routine events and add them to the planner.
        // ------------------------------------------------------------------

        // TODO: skip this step if routines are excluded.

        let reverseSortedNewRoutineEvents: [RoutineEvent] = {
            guard let weekday else {
                return []
            }
            return existingRoutineEvents.values
                .sorted {
                    $0.sortDateMap[weekday]! > $1.sortDateMap[weekday]!
                }
        }()

        for routineEvent in reverseSortedNewRoutineEvents {
            // TODO: grab the index that closest matches other routines from this day.

            // TODO: insert the event there

            let newEvent =
                PlannerEvent(
                    date: plannerDay.date,
                    sortDate: plannerDay.date,
                    routineEvent: routineEvent
                )

            self.insert(newEvent)

        }

        // ------------------------------------------------------------------
        // TODO: Loop over remaining calendar events and add them to the planner.
        // ------------------------------------------------------------------

        let reverseSortedNewCalendarEvents = existingCalendarEvents.values
            .sorted {
                $0.startDate > $1.startDate
            }

        for calendarEvent in reverseSortedNewCalendarEvents {

            guard
                self.validateCalendarEventSynchronization(
                    calendarEvent,
                    birthdayEvents: &birthdayEvents,
                    plannerChipEvents: &plannerChipEvents,
                    regularEvents: &regularEvents,
                    occurrenceEvents: &occurrenceEvents,
                    hiddenCalendarIds: hiddenCalendarIds,
                    plannerDay: plannerDay
                )
            else {
                continue
            }

            self.addCalendarEventToPlanner(
                calendarEvent,
                plannerDay: plannerDay
            )
        }

        // ------------------------------------------------------------------
        // Clean up any remaining storage events.
        // Remove calendar records that no longer exist,
        // otherwise move them to their new planners.
        // ------------------------------------------------------------------

        // TODO: not needed right?
        //        self.updateStaleStorageEvents(
        //            Array(existingCalendarStorageEvents.values),
        //            ekEventStore: ekEventStore
        //        )

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

    private func validateCalendarEventSynchronization(
        _ calendarEvent: EKEvent,
        plannerEvent: PlannerEvent? = nil,
        birthdayEvents: inout [String: EKEvent],
        plannerChipEvents: inout [EKEvent],
        regularEvents: inout [String: EKEvent],
        occurrenceEvents: inout [String: EKEvent],
        hiddenCalendarIds: Set<String>,
        plannerDay: DateInRegion
    ) -> Bool {
        if calendarEvent.calendar.type == .birthday,
            let contactId = calendarEvent.birthdayContactIdentifier
        {
            // Collect birthday events.
            birthdayEvents[contactId] = calendarEvent
            self.deleteIfExists(plannerEvent)
            return false
        }

        if hiddenCalendarIds.contains(
            calendarEvent.calendar.calendarIdentifier
        ) {
            // Calendar is hidden in settings. Remove this record and continue.
            self.deleteIfExists(plannerEvent)
            return false
        }

        if calendarEvent.isAllDay {
            // Collect all-day events as planner chips.
            plannerChipEvents.append(calendarEvent)
            self.deleteIfExists(plannerEvent)
            return false
        }

        if calendarEvent.spansOutsidePlannerDay(
            plannerDay: plannerDay
        ) {
            // Collect events that span outside this day as planner chips.
            plannerChipEvents.append(calendarEvent)

            if !calendarEvent.startDate.belongsTo(plannerDay) {
                // Only display the event if it starts during this day.
                self.deleteIfExists(plannerEvent)
                return false
            }
        }

        if let occurrenceId = calendarEvent.occurrenceId {
            // Collect recurring events.
            occurrenceEvents[occurrenceId] = calendarEvent
        } else {
            // Collect regular timed events.
            regularEvents[
                calendarEvent.calendarItemExternalIdentifier
            ] =
                calendarEvent
        }

        return true
    }

    private func deleteIfExists(_ event: PlannerEvent?) {
        if let event {
            self.delete(event)
        }
    }

    // TODO: what is lost by removing this?
    //    @MainActor
    //    private func upsertCalendarEventToPlanner(
    //        _ calendarEvent: EKEvent,
    //        existingCalendarEvents: inout [String: PlannerEvent],
    //        plannerDay: DateInRegion
    //    ) {
    //        guard
    //            let storageEvent = existingCalendarEvents[
    //                calendarEvent.calendarItemExternalIdentifier
    //            ]
    //        else {
    //            // Event doesn't exist in this planner. Add it.
    //            self.addCalendarEventToPlanner(
    //                calendarEvent,
    //                plannerDay: plannerDay
    //            )
    //            return
    //        }
    //
    //        // Event is already in this planner. Sync it with the calendar event.
    //        storageEvent.syncWithCalendarEvent(calendarEvent)
    //
    //        existingCalendarEvents.removeValue(
    //            forKey: calendarEvent.calendarItemExternalIdentifier
    //        )
    //
    //        // Note: Don't save the context.
    //        // This is part of a larger pipeline.
    //    }

    // TODO: what is lost by removing this?
    //    @MainActor
    //    private func addCalendarEventToPlanner(
    //        // Guaranteed to not have a storage event in the planner.
    //        _ calendarEvent: EKEvent,
    //        plannerDay: DateInRegion
    //    ) {
    //
    //        if calendarEvent.occurrenceId != nil {
    //            // Special case: Automatically create a new record if this is a recurring event occurrence.
    //            self.createPlannerEvent(
    //                for: calendarEvent,
    //                in: plannerDay
    //            )
    //            return
    //        }
    //
    //        guard
    //            let calendarItemExternalIdentifier = calendarEvent
    //                .calendarItemExternalIdentifier
    //        else {
    //            return
    //        }
    //
    //        do {
    //
    //            // Search for a matching event somewhere in storage.
    //            let storageEvents = try fetch(
    //                FetchDescriptor<PlannerEvent>(
    //                    predicate: #Predicate<PlannerEvent> {
    //                        if let calId = $0.calendarItemExternalIdentifier {
    //                            return calId == calendarItemExternalIdentifier
    //                        } else {
    //                            return false
    //                        }
    //                    }
    //                )
    //            )
    //
    //            guard let storageEvent = storageEvents.first else {
    //                // No matching storage event exists. Create a new one.
    //                self.createPlannerEvent(
    //                    for: calendarEvent,
    //                    in: plannerDay
    //                )
    //                return
    //            }
    //
    //            // A matching storage event exists. Sync it with the calendar event and move
    //            // it to the planner day.
    //            storageEvent.syncWithCalendarEvent(calendarEvent)
    //            storageEvent.sortDate = self.getUpperSortDate(
    //                for: plannerDay
    //            )
    //
    //        } catch {
    //            // Failed to fetch a matching storage event. Create a new one.
    //            self.createPlannerEvent(
    //                for: calendarEvent,
    //                in: plannerDay
    //            )
    //        }
    //
    //        // Note: Don't save the context.
    //        // This is part of a larger pipeline.
    //    }

    // TODO: what is lost by removing this?
    //    @MainActor
    //    private func updateStaleStorageEvents(
    //        // Storage events that no longer exist in their calendar day
    //        _ staleStorageEvents: [PlannerEvent],
    //        ekEventStore: EKEventStore
    //    ) {
    //        for staleEvent in staleStorageEvents {
    //
    //            guard
    //                let externalIdentifier = staleEvent
    //                    .calendarItemExternalIdentifier
    //            else {
    //                continue
    //            }
    //
    //            guard
    //                let calendarEvent = ekEventStore.calendarItems(
    //                    withExternalIdentifier: externalIdentifier
    //                ).first as? EKEvent,
    //                calendarEvent.isAllDay == false,
    //                calendarEvent.occurrenceId == nil
    //            else {
    //                // The calendar event is deleted, recurring, or an all-day event.
    //                // Delete the storage event.
    //                self.delete(staleEvent)
    //                continue
    //            }
    //
    //            // The event has moved to a different day. Update its storage event.
    //            staleEvent.syncWithCalendarEvent(calendarEvent)
    //        }
    //    }

}
