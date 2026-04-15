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
        
        print("debug \(planner.datestamp) syncCalendar")

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
                    self.delete(plannerEvent)
                    continue
                }

                existingCalendarEvents.removeValue(forKey: calendarEventId)

                guard
                    self.validateCalendarEventSynchronization(
                        calendarEvent,
                        plannerEvent: plannerEvent,
                        birthdayEvents: &birthdayEvents,
                        calendarDayData: &calendarDayData,
                        hiddenCalendarIds: hiddenCalendarIds,
                        plannerDay: plannerDay
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
                self.validateCalendarEventSynchronization(
                    calendarEvent,
                    birthdayEvents: &birthdayEvents,
                    calendarDayData: &calendarDayData,
                    hiddenCalendarIds: hiddenCalendarIds,
                    plannerDay: plannerDay
                )
            else {
                continue
            }

            self.createPlannerEvent(
                for: calendarEvent,
                in: plannerDay
            )
        }

        // ------------------------------------------------------------------
        // MARK: Load in the contacts for all birthdays.
        // ------------------------------------------------------------------

        let contactStore = CNContactStore()
        calendarDayData.birthdays = contactStore.loadBirthdays(
            for: birthdayEvents
        )

        return calendarDayData
    }

    // MARK: - Helper Functions

    @MainActor
    private func validateCalendarEventSynchronization(
        _ calendarEvent: EKEvent,
        plannerEvent: PlannerEvent? = nil,
        birthdayEvents: inout [String: EKEvent],
        calendarDayData: inout CalendarDayData,
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
            calendarDayData.plannerChipEvents.append(calendarEvent)
            self.deleteIfExists(plannerEvent)
            return false
        }

        if calendarEvent.spansOutsidePlannerDay(
            plannerDay: plannerDay
        ) {
            // Collect events that span outside this day as planner chips.
            calendarDayData.plannerChipEvents.append(calendarEvent)

            if !calendarEvent.startDate.belongsTo(plannerDay) {
                // Only display the event if it starts during this day.
                self.deleteIfExists(plannerEvent)
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
    private func deleteIfExists(_ event: PlannerEvent?) {
        if let event {
            self.delete(event)
        }
    }

}
