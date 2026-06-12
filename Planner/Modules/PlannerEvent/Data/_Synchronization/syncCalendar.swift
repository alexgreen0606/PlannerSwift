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
        for planner: Planner,
        startOfDay: DateInRegion,
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) {

        // MARK: - Load In Calendar Events For This Day

        let nextDay = startOfDay + 1.days
        let calendarEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: startOfDay.date,
                end: nextDay.date,
                calendars: nil  // Match all calendars.
            )
        )

        var newEkEvents = Dictionary(
            uniqueKeysWithValues: calendarEvents.compactMap { event in
                event.calendarItemExternalIdentifier.map { ($0, event) }
            }
        )

        // MARK: - Sync/Delete Existing Calendar Records

        var birthdayEvents: [String: PlannerEvent] = [:]

        let calendarPlannerEvents = getCalendarEvents(on: startOfDay)

        for plannerEvent in calendarPlannerEvents {
            guard
                let calendarItemExternalIdentifier = plannerEvent
                    .calendarContext?
                    .calendarItemExternalIdentifier
            else {
                continue
            }

            // Guard 1: Calendar event is deleted. Remove this record and continue.
            guard
                let ekEvent = newEkEvents[
                    calendarItemExternalIdentifier
                ]
            else {
                deletePlannerEvent(
                    plannerEvent,
                    in: planner,
                    skipSave: true
                )
                continue
            }

            // Remove this event from list of EKEvents that must be created.
            newEkEvents.removeValue(
                forKey: calendarItemExternalIdentifier
            )

            // Guard 2: Calendar is hidden. Remove this record and continue.
            if settings.hiddenCalendarIds.contains(
                ekEvent.calendar.calendarIdentifier
            ) {
                deletePlannerEventIfExists(
                    plannerEvent,
                    in: planner,
                    ekEventStore: ekEventStore
                )
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
            for: Array(newEkEvents.values),
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
                time: ekEvent.startDate,
                datestamp: startOfDay.datestamp,
                sortDate: sortDate,
                calendarEvent: ekEvent
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
