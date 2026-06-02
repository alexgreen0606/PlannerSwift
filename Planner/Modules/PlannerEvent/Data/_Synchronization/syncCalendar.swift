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
        plannerEvents: [PlannerEvent],
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) -> CalendarDayData {
        var calendarDayData = CalendarDayData()

        // MARK: Load in the day's existing calendar events.

        let nextDay = startOfDay + 1.days
        let calendarEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: startOfDay.date,
                end: nextDay.date,
                calendars: nil // Match all calendars.
            )
        )

        var existingCalendarEvents = Dictionary(
            uniqueKeysWithValues: calendarEvents.compactMap { event in
                event.calendarItemExternalIdentifier.map { ($0, event) }
            }
        )

        // MARK: Sync/Delete Existing Planner Events.

        var validEvents: [PlannerEvent] = []
        var birthdayEvents: [String: EKEvent] = [:]

        for plannerEvent in plannerEvents {
            if let calendarItemExternalIdentifier = plannerEvent
                .calendarItemExternalIdentifier
            {
                // MARK: Calendar Event

                guard
                    let calendarEvent = existingCalendarEvents[
                        calendarItemExternalIdentifier
                    ]
                else {
                    // Calendar event is deleted. Remove this record and continue.
                    deletePlannerEvent(
                        plannerEvent,
                        in: planner,
                        skipSave: true
                    )
                    continue
                }

                existingCalendarEvents.removeValue(
                    forKey: calendarItemExternalIdentifier
                )

                guard
                    validateCalendarEventSynchronization(
                        calendarEvent,
                        plannerEvent: plannerEvent,
                        planner: planner,
                        startOfDay: startOfDay,
                        birthdayEvents: &birthdayEvents,
                        calendarDayData: &calendarDayData,
                        ekEventStore: ekEventStore,
                        settings: settings
                    )
                else {
                    continue
                }

                plannerEvent.syncWithCalendarEvent(calendarEvent)
            }

            // Event is still valid. Collect it.
            validEvents.append(plannerEvent)
        }

        // MARK: Create New Calendar Events.

        let reverseSortedNewCalendarEvents = existingCalendarEvents.values
            .sorted {
                $0.startDate > $1.startDate
            }

        for calendarEvent in reverseSortedNewCalendarEvents {
            guard
                validateCalendarEventSynchronization(
                    calendarEvent,
                    planner: planner,
                    startOfDay: startOfDay,
                    birthdayEvents: &birthdayEvents,
                    calendarDayData: &calendarDayData,
                    ekEventStore: ekEventStore,
                    settings: settings
                )
            else {
                continue
            }

            createPlannerEvent(
                for: calendarEvent,
                on: startOfDay
            )
        }

        // MARK: Load In Contacts For Birthdays.

        calendarDayData.birthdays = Self.contactStore.loadBirthdays(
            for: birthdayEvents
        )

        // MARK: Sort Planner Chips Alphabetically.

        calendarDayData.plannerChipEvents = calendarDayData.plannerChipEvents
            .sorted { $0.title < $1.title }

        return calendarDayData
    }

    // MARK: - Helper Functions

    @MainActor
    private func validateCalendarEventSynchronization(
        _ calendarEvent: EKEvent,
        plannerEvent: PlannerEvent? = nil,
        planner: Planner,
        startOfDay: DateInRegion,
        birthdayEvents: inout [String: EKEvent],
        calendarDayData: inout CalendarDayData,
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    )
        -> // True if the event should sync/align with the calendar event, else false.
        Bool
    {
        // MARK: Delete/exclude events from hidden calendars.

        if settings.hiddenCalendarIds.contains(
            calendarEvent.calendar.calendarIdentifier
        ) {
            deletePlannerEventIfExists(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        // MARK: Collect birthday events.

        if calendarEvent.calendar.type == .birthday,
           let contactId = calendarEvent.birthdayContactIdentifier
        {
            birthdayEvents[contactId] = calendarEvent
            deletePlannerEventIfExists(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        // MARK: Collect all-day events as planner chips.

        if calendarEvent.isAllDay {
            calendarDayData.plannerChipEvents.append(calendarEvent)
            deletePlannerEventIfExists(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        // MARK: Collect events that span outside this day as planner chips.

        if calendarEvent.spansOutsidePlanner(
            startOfDay: startOfDay
        ) {
            calendarDayData.plannerChipEvents.append(calendarEvent)

            if !calendarEvent.startDate.belongsToPlanner(startOfDay: startOfDay) {
                // Event does not start on this day. Don't display it as a planner event.
                deletePlannerEventIfExists(
                    plannerEvent,
                    in: planner,
                    ekEventStore: ekEventStore
                )
                return false
            }
        }

        if let occurrenceId = calendarEvent.occurrenceId {
            // MARK: Collect recurring event occurrences.

            calendarDayData.occurrenceEvents[occurrenceId] = calendarEvent

        } else {
            // MARK: Collect regular timed events.

            calendarDayData.regularEvents[
                calendarEvent.calendarItemExternalIdentifier
            ] =
                calendarEvent
        }

        // Calendar event is valid and should be synced into a planner event.
        return true
    }
}
