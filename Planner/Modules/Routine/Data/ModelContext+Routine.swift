//
//  ModelContext+Routine.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    static let baseRoutineDay =
        DateInRegion("2000-06-06", region: .UTC)?
            .dateAtStartOf(.day)

    // MARK: - CREATE

    @MainActor
    func createRoutineEvent(
        at index: Int,
        in sortedRoutineEvents: [RoutineEvent],
        weekday: Weekday
    ) -> UUID? // The ID of the new event.
    {
        let sortDate = generateRoutineEventSortDate(
            at: index,
            in: sortedRoutineEvents,
            weekday: weekday
        )

        let newEvent = RoutineEvent()
        let instance = RoutineEventWeekdayInstance(
            weekday: weekday,
            sortDate: sortDate
        )

        newEvent.weekdayInstances?.append(instance)
        instance.routineEvent = newEvent

        insert(newEvent)

        // Note: Don't save the context here.
        // It can cause flickered duplicates in the list.

        return newEvent.stableId
    }

    // MARK: - READ

    @MainActor
    func loadSortedRoutineEvents(
        for weekday: Weekday,
        reversed: Bool = false
    ) -> [RoutineEvent] {
        do {
            let weekdayRawValue = weekday.rawValue

            let allRoutineEvents = try fetch(
                FetchDescriptor<RoutineEventWeekdayInstance>(
                    predicate: #Predicate {
                        $0.weekdayRawValue == weekdayRawValue
                    },
                    sortBy: [
                        SortDescriptor(
                            \RoutineEventWeekdayInstance.sortDate,
                            order: reversed ? .reverse : .forward
                        ),
                    ]
                )
            )

            return allRoutineEvents.compactMap(\.routineEvent)

        } catch {
            assertionFailure("ERROR loadSortedRoutineEvents: \(error)")
        }

        return []
    }

    @MainActor
    func loadRoutineEventVariant(
        for calendarItemExternalIdentifier: String
    ) -> RoutineEventVariant? {
        do {
            let matchingRoutineVariants = try fetch(
                FetchDescriptor<RoutineEventVariant>(
                    predicate: #Predicate<RoutineEventVariant> {
                        $0.calendarItemExternalIdentifier
                            == calendarItemExternalIdentifier
                    }
                )
            )

            return matchingRoutineVariants.first
        } catch {
            assertionFailure("ERROR loadRoutineEvent: \(error)")
        }

        return nil
    }

    // MARK: - UPDATE

    @MainActor
    func moveRoutineEvent(
        from: Int,
        to: Int,
        on weekday: Weekday,
        sortedRoutineEvents: [RoutineEvent]
    ) {
        let movedEvent = sortedRoutineEvents[from]
        movedEvent.instance(on: weekday)?.sortDate =
            generateRoutineEventSortDate(
                at: to,
                in: sortedRoutineEvents,
                weekday: weekday
            )
        movedEvent.syncedSortDatePlannerEventIds.removeAll()

        safeSave("routineEvent.moveRoutineEvent")
    }

    @MainActor
    func transferRoutineEvents(
        _ events: [RoutineEvent],
        to destinationWeekdays: Set<Weekday>,
        sortedSourceEvents: [RoutineEvent],
        sourceDayOfWeek _: Weekday
    ) {
        guard !destinationWeekdays.isEmpty else { return }

        for event in events {
            updateEventWeekdays(
                event,
                with: destinationWeekdays,
                sortedSourceEvents: sortedSourceEvents
            )
        }

        safeSave("routineEvent.transferRoutineEvents")
    }

    @MainActor
    func updateRoutineEvent(
        with draftRoutineEvent: DraftRoutineEvent,
        sourceRoutineEvent: RoutineEvent?,
        sortedSourceEvents: [RoutineEvent]?
    ) {
        guard !draftRoutineEvent.daysOfWeek.isEmpty else { return }

        let event =
            sourceRoutineEvent
                ?? RoutineEvent()

        event.syncWithDraftRoutineEvent(draftRoutineEvent)

        updateEventWeekdays(
            event,
            with: Set(draftRoutineEvent.daysOfWeek),
            sortedSourceEvents: sortedSourceEvents
        )

        insertIfNeeded(event)
        safeSave("routineEvent.updateRoutineEvent")
    }

    // MARK: - DELETE

    @MainActor
    func deleteAllRoutines(
        ekEventStore: EKEventStore,
        PlannerSyncStore: PlannerSyncService
    ) {
        do {
            let allRoutineEvents = try fetch(
                FetchDescriptor<RoutineEvent>()
            )

            deleteRoutineEvents(
                allRoutineEvents,
                ekEventStore: ekEventStore,
                PlannerSyncStore: PlannerSyncStore
            )

        } catch {
            assertionFailure("ERROR routineEvent.deleteAllRoutines: \(error)")
        }
    }

    @MainActor
    func deleteRoutineEvents(
        _ events: [RoutineEvent],
        ekEventStore: EKEventStore,
        PlannerSyncStore: PlannerSyncService
    ) {
        for event in events {
            deleteRoutineEvent(
                event,
                ekEventStore: ekEventStore,
                skipSave: true,
                PlannerSyncStore: PlannerSyncStore
            )
        }

        safeSave("routineEvent.deleteRoutineEvents")
    }

    @MainActor
    func deleteRoutineEvents(
        _ events: [RoutineEvent],
        from weekday: Weekday,
        ekEventStore: EKEventStore,
        PlannerSyncStore: PlannerSyncService
    ) {
        for event in events {
            if event.safeWeekdayInstances.count == 1 {
                deleteRoutineEvent(
                    event,
                    ekEventStore: ekEventStore,
                    skipSave: true,
                    PlannerSyncStore: PlannerSyncStore
                )
                continue
            }

            // Events will be lazily deleted in this case.
            for instance in event.safeWeekdayInstances
                where instance.weekdayRawValue == weekday.rawValue
            {
                delete(instance)
            }
        }

        safeSave("routineEvent.deleteRoutineEvents")
    }

    @MainActor
    func deleteRoutineEvent(
        _ routineEvent: RoutineEvent,
        ekEventStore: EKEventStore,
        skipSave: Bool = false,
        PlannerSyncStore: PlannerSyncService
    ) {
        for plannerEvent in routineEvent.safePlannerEvents {
            if plannerEvent.isCompleted {
                continue
            }

            if let calendarItemExternalIdentifier = plannerEvent.calendarContext?
                .calendarItemExternalIdentifier
            {
                _ = ekEventStore.attemptDeleteEvent(
                    identifier: calendarItemExternalIdentifier
                )
            }
        }

        var needsCalendarRefresh = false

        // Delete variant records and any calendar references to this routine event.
        for variant in routineEvent.safeVariants {
            if let calendarItemExternalIdentifier = variant
                .calendarItemExternalIdentifier
            {
                _ = ekEventStore.attemptDeleteEvent(
                    identifier: calendarItemExternalIdentifier
                )
                needsCalendarRefresh = true
            }
        }

        delete(routineEvent)

        if needsCalendarRefresh {
            // Refresh calendar data whenever calendar variants exist.
            PlannerSyncStore.invalidateCalendar()
        }

        if !skipSave {
            safeSave("routineEvent.deleteRoutineEvent")
        }
    }

    // MARK: - Change Handlers

    @MainActor
    func handleRoutineEventTitleChange(
        _ routineEvent: RoutineEvent
    ) {
        guard routineEvent.time == nil, let baseDay = Self.baseRoutineDay else {
            return
        }

        // Scan the title for a date.
        guard
            let (date, updatedText) = routineEvent.title.extractTime(
                for: baseDay
            )
        else {
            return
        }

        routineEvent.title = updatedText
        routineEvent.time = date

        safeSave("routineEvent.handleRoutineEventTitleChange")
    }

    // MARK: - Helper Functions

    private func generateNewSortDateNearSiblings(
        for event: RoutineEvent,
        in weekday: Weekday,
        from sortedSourceEvents: [RoutineEvent] = []
    ) -> Date {
        let sortedDestinationEvents = loadSortedRoutineEvents(for: weekday)

        let targetIndex = generateRoutineEventIndex(
            near: event.stableId,
            from: sortedSourceEvents,
            to: sortedDestinationEvents
        )

        return generateRoutineEventSortDate(
            at: targetIndex,
            in: sortedDestinationEvents,
            weekday: weekday
        )
    }

    private func generateRoutineEventSortDate(
        at index: Int,
        in sortedRoutineEvents: [RoutineEvent], // May or may not contain the event being placed.
        weekday: Weekday
    ) -> Date {
        guard let baseDay = Self.baseRoutineDay else {
            return Date()
        }

        return generateSortDate(
            at: index,
            in: sortedRoutineEvents,
            startOfDay: baseDay,
            getSortDate: {
                $0.instance(on: weekday)?.sortDate ?? baseDay.date
            },
            setSortDate: { event, sortDate in
                event.instance(on: weekday)?.sortDate = sortDate
            }
        )
    }

    @MainActor
    private func updateEventWeekdays(
        _ event: RoutineEvent,
        with newWeekdays: Set<Weekday>,
        sortedSourceEvents: [RoutineEvent]? = []
    ) {
        let existingWeekdays = event.weekdays

        let daysToRemove = existingWeekdays.subtracting(newWeekdays)
        for day in daysToRemove {
            // Remove days that no longer exist.
            for instance in event.safeWeekdayInstances
                where instance.weekdayRawValue == day.rawValue
            {
                delete(instance)
            }
        }

        let daysToAdd = newWeekdays.subtracting(existingWeekdays)
        for day in daysToAdd {
            // Place new events near their old siblings.
            event.weekdayInstances?.append(
                RoutineEventWeekdayInstance(
                    weekday: day,
                    sortDate: generateNewSortDateNearSiblings(
                        for: event,
                        in: day,
                        from: sortedSourceEvents ?? []
                    )
                )
            )
        }
    }
}
