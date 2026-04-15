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
        buildConfig: PlannerBuildConfig,
        storageEvents: [PlannerEvent],
        plannerDay: DateInRegion,
        hiddenCalendarIds: Set<String>,
        ekEventStore: EKEventStore
    ) -> CalendarDayData {
        let syncCalendar = buildConfig.cachedCalendarData == nil
        let syncRoutine = buildConfig.syncRoutine

        var calendarDayData =
            buildConfig.cachedCalendarData ?? CalendarDayData()

        // ------------------------------------------------------------------
        // Load in the day's existing calendar events.
        // ------------------------------------------------------------------

        let calendarEvents: [EKEvent] = {
            guard syncCalendar else {
                return []
            }

            let nextDay = plannerDay + 1.days
            return ekEventStore.events(
                matching: ekEventStore.predicateForEvents(
                    withStart: plannerDay.date,
                    end: nextDay.date,
                    calendars: nil
                )
            )
        }()

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
            guard syncRoutine, let weekday else {
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
        // MARK: Sync/Delete Existing Planner Events.
        // ------------------------------------------------------------------

        var birthdayEvents: [String: EKEvent] = [:]
        var validEvents: [PlannerEvent] = []
        var eventsToMove: [PlannerEvent] = []

        for plannerEvent in storageEvents {

            if syncCalendar,
                let calendarEventId = plannerEvent
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

                if let routineEventId = plannerEvent.routineEvent?.stableId {
                    // Mark this recurring event as already existing so it is not re-created.
                    existingRoutineEvents.removeValue(forKey: routineEventId)
                }

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

            } else if syncRoutine, let routineEvent = plannerEvent.routineEvent, let weekday = Weekday.from(planner.datestamp.weekday)
            {
                // MARK: Routine Event
                
                if !routineEvent.weekdays.contains(weekday) {
                    // This weekday was removed. Remove this record and continue.
                    self.delete(plannerEvent)
                    continue
                }

                if planner.finalExcludeRoutine {
                    // Routines are hidden. Remove this record and continue.
                    self.delete(plannerEvent)
                    continue
                }

                existingRoutineEvents.removeValue(forKey: routineEvent.stableId)
                plannerEvent.syncWithRoutineEvent(routineEvent, on: plannerDay)

                if !routineEvent.syncedSortDatePlannerEventIds.contains(
                    plannerEvent.stableId
                ) {
                    // Skip events that need to be re-positioned in the list.
                    eventsToMove.append(plannerEvent)
                    continue
                }

            }

            // Track the events that still exist in the planner.
            validEvents.append(plannerEvent)
        }

        // ------------------------------------------------------------------
        // MARK: Re-position Moved Routine Events.
        // ------------------------------------------------------------------

        if syncRoutine {
            for plannerEvent in eventsToMove {
                guard let routineEvent = plannerEvent.routineEvent else {
                    continue
                }

                // Find a position for the event closest to its routine siblings.
                let targetIndex = generateTargetIndex(
                    near: routineEvent.stableId,
                    from: routineEvents,
                    to: validEvents,
                    destinationComparatorId: { $0.routineEvent?.stableId }
                )

                plannerEvent.sortDate = generateSortDate(
                    at: targetIndex,
                    in: validEvents,
                    plannerDay: plannerDay
                )

                validEvents.insert(plannerEvent, at: targetIndex)

                routineEvent.syncedSortDatePlannerEventIds.insert(
                    plannerEvent.stableId
                )
            }
        }

        // ------------------------------------------------------------------
        // MARK: Create New Routine Events.
        // ------------------------------------------------------------------

        if syncRoutine, !planner.finalExcludeRoutine {

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
        // MARK: Create New Calendar Events.
        // ------------------------------------------------------------------

        if syncCalendar {

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

        }

        if syncCalendar {
            // MARK: Load in the contacts for all birthday events.
            let contactStore = CNContactStore()
            calendarDayData.birthdays = contactStore.loadBirthdays(
                for: birthdayEvents
            )
        }

        self.safeSave("buildPlanner")

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
