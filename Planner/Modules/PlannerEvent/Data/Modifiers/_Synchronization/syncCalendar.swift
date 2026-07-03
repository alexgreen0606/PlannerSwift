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
        ekEventStore: EKEventStore,
        settings: Settings
    ) {

        // MARK: - Load In Calendar Events For This Day

        let nextDay = startOfDay + 1.days
        let ekEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: startOfDay.date,
                end: nextDay.date,
                calendars: nil  // Match all calendars.
            )
        )

        var ekEventDictionary = Dictionary(
            uniqueKeysWithValues: ekEvents.compactMap {
                event -> (String, EKEvent)? in
                guard
                    !settings.hiddenCalendarIds.contains(
                        event.calendar.calendarIdentifier
                    ),
                    let identifier = event.calendarItemExternalIdentifier
                else {
                    return nil
                }

                return (identifier, event)
            }
        )

        // MARK: - Sync/Delete Existing Calendar Records

        var birthdayEvents: [String: PlannerEvent] = [:]

        let calendarRecords = getCalendarRecords(on: startOfDay)

        for plannerEvent in calendarRecords {
            guard
                let calendarItemExternalIdentifier = plannerEvent
                    .eKEventContext?
                    .calendarItemExternalIdentifier
            else {
                continue
            }

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

            plannerEvent.syncWithCalendarEvent(ekEvent)
        }

        // MARK: - Create New Calendar Records

        bulkCreatePlannerEvents(
            for: Array(ekEventDictionary.values),
            on: startOfDay,
            birthdayEvents: &birthdayEvents
        )

        // MARK: - Load In Contacts For Birthdays

        Self.contactStore.syncBirthdayContacts(
            for: birthdayEvents
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

                return generateSortDate(
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
