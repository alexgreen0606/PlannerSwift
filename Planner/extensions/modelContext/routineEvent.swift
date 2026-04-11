//
//  routineEvent.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    static let baseRoutineDay = DateInRegion("2000-06-06", region: .UTC)?
        .dateAtStartOf(.day)

    // MARK: - CREATE

    @MainActor
    func createRoutineEvent(
        at index: Int,
        in events: [RoutineEvent],
        weekday: Weekday
    ) -> UUID?  // The ID of the new event.
    {
        let sortDate = self.generateRoutineEventSortDate(
            at: index,
            in: events,
            weekday: weekday
        )

        let newEvent = RoutineEvent()
        newEvent.sortDateMap[weekday] = sortDate

        self.insert(newEvent)
        self.safeSave("routineEvent.createRoutineEvent")

        return newEvent.stableId
    }

    // MARK: - READ

    @MainActor
    func loadSortedRoutineEvents(
        for weekday: Weekday,
        reversed: Bool = false
    ) -> [RoutineEvent] {
        do {
            let allRoutineEvents = try self.fetch(
                FetchDescriptor<RoutineEvent>()
            )

            return weekday.sortedEvents(
                in: allRoutineEvents,
                reversed: reversed
            )

        } catch {
            assertionFailure("ERROR loadSortedRoutineEvents: \(error)")
        }

        return []
    }

    // MARK: - UPDATE

    @MainActor
    func moveRoutineEvent(
        from: Int,
        to: Int,
        on weekday: Weekday,
        sortedEvents: [RoutineEvent]
    ) {
        let movedEvent = sortedEvents[from]
        movedEvent.sortDateMap[weekday] = self.generateRoutineEventSortDate(
            at: to,
            in: sortedEvents,
            weekday: weekday
        )

        self.safeSave("routineEvent.moveRoutineEvent")
    }

    @MainActor
    func transferRoutineEvents(
        _ events: [RoutineEvent],
        to destinationWeekdays: Set<Weekday>,
        sortedSourceEvents: [RoutineEvent],
        sourceDayOfWeek: Weekday
    ) {
        guard !destinationWeekdays.isEmpty else { return }

        for event in events {
            self.updateEventWeekdays(
                event,
                with: destinationWeekdays,
                sortedSourceEvents: sortedSourceEvents
            )
        }

        self.safeSave("routineEvent.transferRoutineEvents")
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

        self.updateEventWeekdays(
            event,
            with: Set(draftRoutineEvent.daysOfWeek),
            sortedSourceEvents: sortedSourceEvents
        )

        self.insertIfNeeded(event)
        self.safeSave("routineEvent.updateRoutineEvent")
    }

    // MARK: - DELETE

    @MainActor
    func deleteRoutineEvents(
        from events: [RoutineEvent],
        for weekday: Weekday
    ) {
        for event in events {
            guard event.sortDateMap[weekday] != nil else {
                continue
            }

            if event.sortDateMap.keys.count == 1 {
                self.delete(event)
                continue
            }

            event.sortDateMap.removeValue(forKey: weekday)
        }

        self.safeSave("routineEvent.deleteRoutineEvents")
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

    // MARK: - Helper Functions

    private func generateNewSortDateNearSiblings(
        for event: RoutineEvent,
        in weekday: Weekday,
        from sortedSourceEvents: [RoutineEvent] = []
    ) -> Date {
        let sortedDestinationEvents = self.loadSortedRoutineEvents(for: weekday)

        let targetIndex = generateTargetIndex(
            near: event.stableId,
            from: sortedSourceEvents,
            to: sortedDestinationEvents
        )

        return self.generateRoutineEventSortDate(
            at: targetIndex,
            in: sortedDestinationEvents,
            weekday: weekday
        )
    }

    private func generateRoutineEventSortDate(
        at index: Int,
        in sortedEvents: [RoutineEvent],  // May or may not contain the event being placed.
        weekday: Weekday
    ) -> Date {
        guard let baseDay = Self.baseRoutineDay else {
            return Date()
        }

        return generateSortDate(
            at: index,
            in: sortedEvents,
            plannerDay: baseDay,
            getSortDate: {
                $0.sortDateMap[weekday]!
            },
            setSortDate: { event, sortDate in
                event.sortDateMap[weekday] = sortDate
            }
        )
    }

    @MainActor
    private func updateEventWeekdays(
        _ event: RoutineEvent,
        with newWeekdays: Set<Weekday>,
        sortedSourceEvents: [RoutineEvent]? = []
    ) {
        let existingWeekdays = Set(event.sortDateMap.keys)

        let daysToRemove = existingWeekdays.subtracting(newWeekdays)
        for day in daysToRemove {
            // Remove days that no longer exist.
            event.sortDateMap.removeValue(forKey: day)
        }

        let daysToAdd = newWeekdays.subtracting(existingWeekdays)
        for day in daysToAdd {
            // Place new events near their old siblings.
            event.sortDateMap[day] = generateNewSortDateNearSiblings(
                for: event,
                in: day,
                from: sortedSourceEvents ?? []
            )
        }
    }

}
