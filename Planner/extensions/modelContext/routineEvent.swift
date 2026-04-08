//
//  routineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {

    static let baseRoutineDay = DateInRegion("2000-06-06", region: .UTC)

    @MainActor
    func createRoutineEvent(
        at index: Int,
        in events: [RoutineEvent],
        dayOfWeek: DayOfWeek
    ) -> UUID?  // The ID of the new event.
    {
        guard let baseDay = Self.baseRoutineDay else {
            return nil
        }

        let sortDate = generateSortDate(
            at: index,
            in: events,
            plannerDay: baseDay
        )

        let newEvent = RoutineEvent(
            dayOfWeek: dayOfWeek,
            sortDate: sortDate
        )

        self.insert(newEvent)
        self.safeSave("routineEvent.createRoutineEvent")

        return newEvent.stableId
    }

    @MainActor
    func moveRoutineEvent(
        from: Int,
        to: Int,
        sortedEvents: [RoutineEvent]
    ) {
        guard let baseDay = Self.baseRoutineDay, from != to else { return }

        let movedEvent = sortedEvents[from]
        movedEvent.sortDate = generateSortDate(
            at: to,
            in: sortedEvents,
            plannerDay: baseDay
        )

        self.safeSave("routineEvent.moveRoutineEvent")
    }

    @MainActor
    func updateRoutineEvent(
        with draftRoutineEvent: DraftRoutineEvent,
        sourceRoutineEvent: RoutineEvent?
    ) {
        guard !draftRoutineEvent.daysOfWeek.isEmpty else { return }

        let event =
            sourceRoutineEvent
            ?? RoutineEvent(
                dayOfWeek: DayOfWeek.monday,
                sortDate: draftRoutineEvent.date
            )

        event.title = draftRoutineEvent.title
        event.time = draftRoutineEvent.hasTime ? draftRoutineEvent.date : nil

        if draftRoutineEvent.daysOfWeek.count > 1 {

            // MARK: Recurring Routine Event

            let recurringRoutineEvent = {
                if let existing = sourceRoutineEvent?.recurringParent {
                    existing.title = draftRoutineEvent.title
                    existing.time = event.time
                    return existing
                }

                // TODO: why am I storing title and time at all?
                let newRecurringEvent = RecurringRoutineEvent(
                    title: draftRoutineEvent.title,
                    time: event.time
                )

                if let sourceRoutineEvent {
                    // Include the source event so it can be handled below.
                    newRecurringEvent.events.append(sourceRoutineEvent)
                }

                return newRecurringEvent
            }()

            var daysToSync = draftRoutineEvent.daysOfWeek

            for existingEvent in recurringRoutineEvent.events {
                guard daysToSync.contains(existingEvent.dayOfWeek) else {
                    // Delete the stale event.
                    self.delete(existingEvent)
                    continue
                }

                daysToSync.remove(existingEvent.dayOfWeek)

                // Sync the existing event with the parent.
                existingEvent.syncWithRecurringRoutineEvent(
                    recurringRoutineEvent
                )
            }

            // Place at the top of each planner it does not exist in.
            for day in daysToSync {
                let newEvent = RoutineEvent(
                    dayOfWeek: day,
                    // TODO: maybe track the event above and below it, and try to place between those
                    sortDate: getUpperSortDate(for: day)
                )
                newEvent.syncWithRecurringRoutineEvent(recurringRoutineEvent)
                recurringRoutineEvent.events.append(newEvent)
            }

            self.insertIfNeeded(recurringRoutineEvent)

        } else if let destinationDay = draftRoutineEvent.daysOfWeek.first {

            // MARK: Single Routine Event

            event.dayOfWeek = destinationDay

            if let staleRecurringRoutineEvent = sourceRoutineEvent?
                .recurringParent
            {
                // Delete stale recurring routine event record.
                self.deleteRecurringRoutineEvent(
                    staleRecurringRoutineEvent,
                    safeDays: [destinationDay]
                )
                event.recurringParent = nil
            }
        }

        // TODO: always place transfered list items at the top for checklists too.

        self.insertIfNeeded(event)

        self.safeSave("routineEvent.updateRoutineEvent")
    }

    @MainActor
    func handleRoutineEventTitleChange(
        _ routineEvent: RoutineEvent
    ) {
        guard routineEvent.time == nil, let baseDay = Self.baseRoutineDay else {
            return
        }

        // TODO: update every event

        // Scan the title for a date.
        guard
            let (date, updatedText) = routineEvent.title.separateDate(
                for: baseDay
            )
        else {
            return
        }

        routineEvent.title = updatedText
        routineEvent.time = date

        self.safeSave("routineEvent.handleRoutineEventTitleChange")
    }

    func deleteRecurringRoutineEvent(
        _ recurringRoutineEvent: RecurringRoutineEvent,
        safeDays: Set<DayOfWeek> = []
    ) {
        for staleEvent in recurringRoutineEvent.events
        where !safeDays.contains(staleEvent.dayOfWeek) {
            self.delete(staleEvent)
        }

        self.delete(recurringRoutineEvent)

        // Note: Don't save context here.
        // Typically part of a larger pipeline.
    }

    func deleteRoutineEvents(
        _ events: [RoutineEvent]
    ) {
        for event in events {
            if let recurringRoutineEvent = event.recurringParent {
                self.deleteRecurringRoutineEvent(recurringRoutineEvent)
                continue
            }

            self.delete(event)
        }

        self.safeSave("routineEvent.deleteRoutineEvents")
    }

    // MARK: - Helper Functions

    private func getUpperSortDate(for dayOfWeek: DayOfWeek)
        -> Date
    {
        guard let baseDay = Self.baseRoutineDay else {
            return Date()
        }

        do {
            let routineEvents = try self.fetch(
                FetchDescriptor<RoutineEvent>(
                    sortBy: [
                        SortDescriptor(\RoutineEvent.sortDate)
                    ]
                )
            ).filter {
                $0.dayOfWeek == dayOfWeek
            }

            return generateSortDate(
                at: 0,
                in: routineEvents,
                plannerDay: baseDay
            )

        } catch {
            assertionFailure(
                "ERROR routineEvent.getUpperSortDate: \(error)"
            )
        }

        return generateSortDate(at: 0, in: [], plannerDay: baseDay)
    }

}
