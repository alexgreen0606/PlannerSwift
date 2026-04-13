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

        var validEvents: [PlannerEvent] = []

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

                if let routineEventId = plannerEvent.routineEvent?.stableId {
                    // Mark this recurring event as already existing so it is not re-created.
                    existingRoutineEvents.removeValue(forKey: routineEventId)
                }

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

            } else if let routineEvent = plannerEvent.routineEvent {
                // MARK: Routine Event

                existingRoutineEvents.removeValue(forKey: routineEvent.stableId)
                plannerEvent.syncWithRoutineEvent(routineEvent, on: plannerDay)

            }

            // Track the events that still exist in the planner.
            validEvents.append(plannerEvent)
        }

        // ------------------------------------------------------------------
        // Loop over remaining routine events and add them to the planner.
        // ------------------------------------------------------------------

        if !planner.finalExcludeRoutine {

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

                // Find a position for the event closest to its routine siblings.
                // Defaults to top of list otherwise.
                let targetIndex = generateTargetIndex(
                    near: routineEvent.stableId,
                    from: routineEvents,
                    to: validEvents,
                    destinationComparatorId: { $0.routineEvent?.stableId }
                )

                let sortDate = generateSortDate(
                    at: targetIndex,
                    in: validEvents,
                    plannerDay: plannerDay
                )

                let newEvent =
                    PlannerEvent(
                        date: plannerDay.date,
                        sortDate: sortDate,
                        routineEvent: routineEvent,
                        plannerDay: plannerDay
                    )

                self.insert(newEvent)

                // Track the event at its position in the planner.
                validEvents.insert(newEvent, at: targetIndex)
            }

        }

        // ------------------------------------------------------------------
        // Loop over remaining calendar events and add them to the planner.
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

            self.createPlannerEvent(
                for: calendarEvent,
                in: plannerDay
            )
        }

        // ------------------------------------------------------------------
        // Load in the contacts for all birthday events.
        // ------------------------------------------------------------------

        let contactStore = CNContactStore()
        let birthdays = contactStore.loadBirthdays(for: birthdayEvents)

        self.safeSave("buildCalendar")

        return CalendarDayData(
            plannerChipEvents: plannerChipEvents,
            birthdays: birthdays,
            occurrenceEvents: occurrenceEvents,
            regularEvents: regularEvents
        )
    }

    // MARK: - Helper Functions

    @MainActor
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

    @MainActor
    private func deleteIfExists(_ event: PlannerEvent?) {
        if let event {
            self.delete(event)
        }
    }

}
