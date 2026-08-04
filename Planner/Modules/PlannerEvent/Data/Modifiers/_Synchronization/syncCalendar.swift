//
//  syncCalendar.swift
//  Planner
//
//  Created by Alex Green on 4/15/26.
//

import Contacts
import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    private static let contactStore = CNContactStore()

    @MainActor
    func syncCalendar(
        startOfDay: DateInRegion,
        calendarService: CalendarService,
        settings: Settings
    ) {

        // MARK: - Load In Calendar Events For This Day

        let ekEventStore = calendarService.ekEventStore

        let nextDay = startOfDay + 1.days
        let ekEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: startOfDay.date,
                end: nextDay.date,
                calendars: calendarService.sortedVisibleCalendars
            )
        )

        var ekEventDictionary = Dictionary(
            uniqueKeysWithValues: ekEvents.compactMap {
                event -> (String, EKEvent)? in
                guard let identifier = event.calendarItemExternalIdentifier
                else {
                    return nil
                }

                return (identifier, event)
            }
        )

        // MARK: - Sync/Delete Existing Calendar Records

        var birthdayEvents: [String: PlannerEvent] = [:]
        var invalidatedPositionPlannerEvents: [PlannerEvent] = []

        let calendarRecords = getCalendarRecords(on: startOfDay)

        for plannerEvent in calendarRecords {
            guard
                let ekEventContext = plannerEvent.eKEventContext
            else {
                continue
            }

            let calendarItemExternalIdentifier = ekEventContext
                .calendarItemExternalIdentifier

            // Guard 1: Calendar event is deleted. Remove this record and continue.
            guard
                let ekEvent = ekEventDictionary[
                    calendarItemExternalIdentifier
                ]
            else {
                delete(plannerEvent)
                continue
            }

            // Remove event from list of EKEvents that must be created.
            ekEventDictionary.removeValue(
                forKey: calendarItemExternalIdentifier
            )

            // Guard 2: Calendar is hidden. Remove this record and continue.
            if settings.hiddenCalendarIds.contains(
                ekEvent.calendar.calendarIdentifier
            ) {
                delete(plannerEvent)
                continue
            }

            // Collect birthday events so their contacts can be fetched.
            if ekEvent.calendar.type == .birthday,
                let contactId = ekEvent.birthdayContactIdentifier
            {
                birthdayEvents[contactId] = plannerEvent
            }

            // Collect all-day events that are now timed.
            if !ekEvent.isAllDay && ekEventContext.isAllDay {
                invalidatedPositionPlannerEvents.append(plannerEvent)
            }

            plannerEvent.syncWithEkEvent(ekEvent)
        }

        // MARK: - Re-position All-Day Events That Are Now Timed

        if !invalidatedPositionPlannerEvents.isEmpty {
            var sortedPlannerEvents = getSortedListEvents(on: startOfDay)

            let reverseSortedEvents = invalidatedPositionPlannerEvents.sorted {
                ($0.eKEventContext?.startDate ?? .distantPast)
                    > ($1.eKEventContext?.startDate ?? .distantPast)
            }

            for plannerEvent in reverseSortedEvents {
                plannerEvent.sortDate = generatePlannerEventSortDate(
                    at: 0,
                    in: sortedPlannerEvents,
                    startOfDay: startOfDay
                )

                // Track the event at its new position in the planner.
                sortedPlannerEvents.insert(plannerEvent, at: 0)
            }
        }

        // MARK: - Create New Calendar Records

        bulkCreatePlannerEvents(
            for: Array(ekEventDictionary.values),
            on: startOfDay,
            birthdayEvents: &birthdayEvents
        )

        // TODO: move events to top that were all-day and are now timed.

        // MARK: - Load In Contacts For Birthdays

        Self.contactStore.syncBirthdayContacts(
            for: birthdayEvents,
            calendarService: calendarService
        )
    }

    // MARK: - Helper Function

    @MainActor
    private func bulkCreatePlannerEvents(
        for ekEvents: [EKEvent],
        on startOfDay: DateInRegion,
        birthdayEvents: inout [String: PlannerEvent]
    ) {
        guard !ekEvents.isEmpty else {
            return
        }

        var listEvents = getSortedListEvents(on: startOfDay)

        let reverseSortedEkEvents = ekEvents.sorted {
            $0.startDate > $1.startDate
        }

        for ekEvent in reverseSortedEkEvents {
            let sortDate = {
                guard !ekEvent.isAllDay else {
                    return ekEvent.startDate ?? Date.now
                }

                return generatePlannerEventSortDate(
                    at: 0,
                    in: listEvents,
                    startOfDay: startOfDay
                )
            }()

            let newEvent = PlannerEvent(
                ekEvent: ekEvent,
                sortDate: sortDate
            )

            insert(newEvent)

            // Collect birthday events so their contacts can be fetched.
            if ekEvent.calendar.type == .birthday,
                let contactId = ekEvent.birthdayContactIdentifier
            {
                birthdayEvents[contactId] = newEvent
            }

            listEvents.insert(newEvent, at: 0)
        }
    }
}
