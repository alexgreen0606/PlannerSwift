//
//  syncCalendar.swift
//  Planner
//
//  Created by Alex Green on 4/15/26.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    @MainActor
    func syncCalendar(
        for planner: Planner,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        hiddenCalendarIds: Set<String>,
        ekEventStore: EKEventStore
    ) -> CalendarDayData {
        var calendarDayData = CalendarDayData()

        // ------------------------------------------------------------------
        // MARK: Load in the day's existing calendar events.
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
        // MARK: Sync/Delete Existing Planner Events.
        // ------------------------------------------------------------------

        var birthdayEvents: [String: EKEvent] = [:]
        var validEvents: [PlannerEvent] = []

        for plannerEvent in storageEvents {
            if let calendarEventId = plannerEvent
                .calendarItemExternalIdentifier
            {
                // MARK: Calendar Event

                guard
                    let calendarEvent = existingCalendarEvents[calendarEventId]
                else {
                    // Calendar event is deleted. Remove this record and continue.
                    deletePlannerEvent(
                        plannerEvent,
                        in: planner,
                        skipSave: true
                    )
                    continue
                }

                existingCalendarEvents.removeValue(forKey: calendarEventId)

                guard
                    validateCalendarEventSynchronization(
                        calendarEvent,
                        plannerEvent: plannerEvent,
                        planner: planner,
                        birthdayEvents: &birthdayEvents,
                        calendarDayData: &calendarDayData,
                        hiddenCalendarIds: hiddenCalendarIds,
                        plannerDay: plannerDay,
                        ekEventStore: ekEventStore
                    )
                else {
                    continue
                }

                plannerEvent.syncWithCalendarEvent(calendarEvent)
            }

            // Track the events that still exist in the planner.
            validEvents.append(plannerEvent)
        }

        // ------------------------------------------------------------------
        // MARK: Create New Calendar Events.

        // ------------------------------------------------------------------

        let reverseSortedNewCalendarEvents = existingCalendarEvents.values
            .sorted {
                $0.startDate > $1.startDate
            }

        for calendarEvent in reverseSortedNewCalendarEvents {
            guard
                validateCalendarEventSynchronization(
                    calendarEvent,
                    planner: planner,
                    birthdayEvents: &birthdayEvents,
                    calendarDayData: &calendarDayData,
                    hiddenCalendarIds: hiddenCalendarIds,
                    plannerDay: plannerDay,
                    ekEventStore: ekEventStore
                )
            else {
                continue
            }

            createPlannerEvent(
                for: calendarEvent,
                in: plannerDay
            )
        }

        // ------------------------------------------------------------------
        // MARK: Load In Contacts For Birthdays.

        // ------------------------------------------------------------------

        let contactStore = CNContactStore()
        calendarDayData.birthdays = contactStore.loadBirthdays(
            for: birthdayEvents
        )

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
        birthdayEvents: inout [String: EKEvent],
        calendarDayData: inout CalendarDayData,
        hiddenCalendarIds: Set<String>,
        plannerDay: DateInRegion,
        ekEventStore: EKEventStore
    ) -> Bool {
        if calendarEvent.calendar.type == .birthday,
           let contactId = calendarEvent.birthdayContactIdentifier
        {
            // Collect birthday events.
            birthdayEvents[contactId] = calendarEvent
            deletePlannerEventIfExists(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        if hiddenCalendarIds.contains(
            calendarEvent.calendar.calendarIdentifier
        ) {
            // Calendar is hidden in settings. Remove this record and continue.
            deletePlannerEventIfExists(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        if calendarEvent.isAllDay {
            // Collect all-day events as planner chips.
            calendarDayData.plannerChipEvents.append(calendarEvent)
            deletePlannerEventIfExists(
                plannerEvent,
                in: planner,
                ekEventStore: ekEventStore
            )
            return false
        }

        if calendarEvent.spansOutsidePlannerDay(
            plannerDay
        ) {
            // Collect events that span outside this day as planner chips.
            calendarDayData.plannerChipEvents.append(calendarEvent)

            if !calendarEvent.startDate.belongsTo(plannerDay) {
                // Only display the event if it starts during this day.
                deletePlannerEventIfExists(
                    plannerEvent,
                    in: planner,
                    ekEventStore: ekEventStore
                )
                return false
            }
        }

        if let occurrenceId = calendarEvent.occurrenceId {
            // Collect recurring events.
            calendarDayData.occurrenceEvents[occurrenceId] = calendarEvent
        } else {
            // Collect regular timed events.
            calendarDayData.regularEvents[
                calendarEvent.calendarItemExternalIdentifier
            ] =
                calendarEvent
        }

        return true
    }

    @MainActor
    private func deletePlannerEventIfExists(
        _ event: PlannerEvent?,
        in planner: Planner,
        ekEventStore: EKEventStore
    ) {
        if let event {
            deletePlannerEvent(
                event,
                in: planner,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }
    }
}
