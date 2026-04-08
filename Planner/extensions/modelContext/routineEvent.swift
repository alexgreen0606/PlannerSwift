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

    static let baseRoutineDay = DateInRegion("2000-06-06", region: .UTC)?
        .dateAtStartOf(.day)

    // MARK: - CREATE

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
            plannerDay: baseDay,
            getSortDate: {
                $0.sortDateMap[dayOfWeek]!
            },
            setSortDate: { event, sortDate in
                event.sortDateMap[dayOfWeek] = sortDate
            }
        )

        let newEvent = RoutineEvent()
        newEvent.sortDateMap[dayOfWeek] = sortDate

        self.insert(newEvent)
        self.safeSave("routineEvent.createRoutineEvent")

        return newEvent.stableId
    }

    // MARK: - UPDATE

    @MainActor
    func moveRoutineEvent(
        from: Int,
        to: Int,
        on dayOfWeek: DayOfWeek,
        sortedEvents: [RoutineEvent]
    ) {
        guard let baseDay = Self.baseRoutineDay, from != to else { return }

        let movedEvent = sortedEvents[from]
        movedEvent.sortDateMap[dayOfWeek] = generateSortDate(
            at: to,
            in: sortedEvents,
            plannerDay: baseDay,
            getSortDate: {
                $0.sortDateMap[dayOfWeek]!
            },
            setSortDate: { event, sortDate in
                event.sortDateMap[dayOfWeek] = sortDate
            }
        )

        self.safeSave("routineEvent.moveRoutineEvent")
    }

    @MainActor
    func transferRoutineEvents(
        _ events: [RoutineEvent],
        to daysOfWeek: Set<DayOfWeek>
    ) {
        guard !daysOfWeek.isEmpty else { return }

        for event in events {
            self.updateRoutineEvent(
                with: DraftRoutineEvent(
                    date: event.time ?? Date(),
                    hasTime: event.time != nil,
                    title: event.title,
                    daysOfWeek: daysOfWeek
                ),
                sourceRoutineEvent: event,
                sourceNeighborIds: NeighborIds(upperId: nil, lowerId: nil),  // TODO: use this
                skipSave: true
            )
        }

        self.safeSave("routineEvent.transferRoutineEvent")
    }

    @MainActor
    func updateRoutineEvent(
        with draftRoutineEvent: DraftRoutineEvent,
        sourceRoutineEvent: RoutineEvent?,
        sourceNeighborIds: NeighborIds?,
        skipSave: Bool = false
    ) {
        guard !draftRoutineEvent.daysOfWeek.isEmpty else { return }

        let event =
            sourceRoutineEvent
            ?? RoutineEvent()

        event.syncWithDraftRoutineEvent(draftRoutineEvent)

        let daysToSync = Set(draftRoutineEvent.daysOfWeek)
        let existingDays = Set(event.sortDateMap.keys)

        let daysToRemove = existingDays.subtracting(daysToSync)
        for day in daysToRemove {
            // Remove days that no longer exist.
            event.sortDateMap.removeValue(forKey: day)
        }

        let daysToAdd = daysToSync.subtracting(existingDays)
        for day in daysToAdd {
            // Add new days and place the event near any corresponding neighbors from the source.
            event.sortDateMap[day] = getSortDate(
                between: sourceNeighborIds,
                in: day
            )
        }

        // TODO: always place transfered list items at the top for checklists.

        self.insertIfNeeded(event)

        if !skipSave {
            self.safeSave("routineEvent.updateRoutineEvent")
        }
    }

    // MARK: - DELETE

    func deleteRoutineEvents(
        _ events: [RoutineEvent]
    ) {
        for event in events {
            self.delete(event)
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

    // Generates a sortDate for an event below a given neighbor's stableId.
    private func getSortDate(
        between neighborIds: NeighborIds? = nil,
        in dayOfWeek: DayOfWeek
    )
        -> Date
    {
        guard let baseDay = Self.baseRoutineDay else {
            return Date()
        }

        do {
            let routineEvents = try self.fetch(
                FetchDescriptor<RoutineEvent>()
            ).filter {
                $0.sortDateMap[dayOfWeek] != nil
            }.sorted {
                $0.sortDateMap[dayOfWeek]! < $1.sortDateMap[dayOfWeek]!
            }

            var targetIndex: Int?

            if let upperId = neighborIds?.upperId,
                let index = routineEvents.firstIndex(where: {
                    $0.stableId == upperId
                })
            {
                // Place below the upper neighbor.
                targetIndex = index + 1
            } else if let lowerId = neighborIds?.lowerId,
                let index = routineEvents.firstIndex(where: {
                    $0.stableId == lowerId
                })
            {
                // Place above the lower neighbor.
                targetIndex = index
            }

            return generateSortDate(
                at: targetIndex ?? 0,
                in: routineEvents,
                plannerDay: baseDay,
                getSortDate: {
                    $0.sortDateMap[dayOfWeek]!
                },
                setSortDate: { event, sortDate in
                    event.sortDateMap[dayOfWeek] = sortDate
                }
            )

        } catch {
            assertionFailure(
                "ERROR routineEvent.getSortDate: \(error)"
            )
        }

        return generateSortDate(
            at: 0,
            in: [] as [RoutineEvent],
            plannerDay: baseDay,
            getSortDate: {
                $0.sortDateMap[dayOfWeek]!
            },
            setSortDate: { event, sortDate in
                event.sortDateMap[dayOfWeek] = sortDate
            }
        )
    }

}
