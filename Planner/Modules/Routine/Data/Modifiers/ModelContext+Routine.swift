//
//  ModelContext+Routine.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import EventKit
import SwiftData
import SwiftDate

extension ModelContext {
    static let baseRoutineDate =
        DateInRegion("2000-06-06", region: .UTC)?
        .dateAtStartOf(.day)

    // MARK: - ENSURE

    @MainActor
    func ensureRoutines() {
        do {
            let existingRoutines = try fetch(
                FetchDescriptor<Routine>()
            )

            let existingWeekdays = Set(existingRoutines.map(\.weekdayRawValue))

            let allWeekdayRawValues = Set(Weekday.allCases.map(\.rawValue))

            let missingWeekdays = allWeekdayRawValues.subtracting(
                existingWeekdays
            )

            guard !missingWeekdays.isEmpty else {
                return
            }

            for missingWeekday in missingWeekdays {
                insert(
                    Routine(weekdayRawValue: missingWeekday)
                )
            }

            safeSave("ModelContext+Routine ensureRoutines")
        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine ensureRoutines: \(error)"
            )
        }
    }

    // MARK: - CREATE

    @MainActor
    func createRoutineEventContext(
        at index: Int,
        in sortedRoutineEventContexts: [RoutineEventContext],
        routine: Routine
    ) -> /// The ID of the new event.
        UUID?
    {
        let sortDate = generateRoutineEventSortDate(
            at: index,
            in: sortedRoutineEventContexts,
            for: routine
        )

        let routineEventContext = RoutineEventContext()
        let _ = RoutineEvent(
            routine: routine,
            routineEventContext: routineEventContext,
            sortDate: sortDate
        )

        insert(routineEventContext)

        // Note: Don't save the context here.
        // It can cause flickered duplicates in the list.

        return routineEventContext.stableId
    }

    // MARK: - READ

    @MainActor
    func getSortedRoutineEventContexts(
        for routine: Routine,
        excluding: Set<UUID> = [],
        reversed: Bool = false
    ) -> [RoutineEventContext] {
        let allRoutineEvents = getSortedRoutineEvents(
            for: routine,
            excluding: excluding,
            reversed: reversed
        )

        return allRoutineEvents.compactMap(\.routineEventContext)
    }

    @MainActor
    func getSortedRoutineEvents(
        for routine: Routine,
        excluding: Set<UUID> = [],
        reversed: Bool = false
    ) -> [RoutineEvent] {
        do {
            return try fetch(
                FetchDescriptor<RoutineEvent>(
                    predicate:
                        RoutineEvent.routineEvents(
                            for: routine,
                            excluding: excluding
                        ),
                    sortBy: [
                        SortDescriptor(
                            \RoutineEvent.sortDate,
                            order: reversed ? .reverse : .forward
                        )
                    ]
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine getSortedRoutineEvents: \(error)"
            )
        }

        return []
    }

    @MainActor
    func getRoutine(
        for weekdayRawValue: String
    ) -> Routine? {
        do {
            return try fetch(
                FetchDescriptor<Routine>(
                    predicate: Routine.routines(
                        for: weekdayRawValue
                    )
                )
            ).first
        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine getRoutine: \(error)"
            )
        }

        return nil
    }

    @MainActor
    func getRoutines(
        for weekdays: Set<Weekday>
    ) -> [Routine] {
        do {
            return try fetch(
                FetchDescriptor<Routine>(
                    predicate: Routine.routines(
                        for: weekdays
                    )
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine getRoutines: \(error)"
            )
        }

        return []
    }

    // MARK: - UPDATE

    @MainActor
    func moveRoutineEvent(
        from: Int,
        to: Int,
        sortedRoutineEventContexts: [RoutineEventContext],
        routine: Routine
    ) {
        let movedEvent = sortedRoutineEventContexts[from]

        guard let movedInstance = movedEvent.routineEvent(for: routine) else {
            return
        }

        movedInstance.sortDate =
            generateRoutineEventSortDate(
                at: to,
                in: sortedRoutineEventContexts,
                for: routine
            )

        // Update sort date version so that each routine event record re-positions itself in its planner.
        movedInstance.sortDateVersion += 0.1

        safeSave("ModelContext+Routine moveRoutineEvent")
    }

    @MainActor
    func bulkUpdateRoutineEventWeekdays(
        _ routineEventContexts: [RoutineEventContext],
        to destinationWeekdays: Set<Weekday>,
        sourceSortedRoutineEventContexts: [RoutineEventContext],
        ekEventStore: EKEventStore
    ) {
        guard !destinationWeekdays.isEmpty else { return }

        for routineEventContext in routineEventContexts {
            updateRoutineEventContextWeekdays(
                routineEventContext,
                with: destinationWeekdays,
                sourceSortedRoutineEventContexts: sourceSortedRoutineEventContexts,
                ekEventStore: ekEventStore
            )
        }

        safeSave("ModelContext+Routine bulkUpdateRoutineEventWeekdays")
    }

    // MARK: - DELETE

    @MainActor
    func deleteRoutineEvents(
        _ routineEventContexts: [RoutineEventContext],
        ekEventStore: EKEventStore,
    ) {
        var staleCalendarItemExternalIdentifiers: Set<String> = []

        for routineEventContext in routineEventContexts {
            staleCalendarItemExternalIdentifiers.formUnion(
                deleteRoutineEventContext(
                    routineEventContext,
                    inLoop: true,
                    ekEventStore: ekEventStore
                )
            )
        }

        // Delete all planner events linked to the deleted calendar events.
        deleteCalendarRecords(
            calendarItemExternalIdentifiers:
                staleCalendarItemExternalIdentifiers
        )

        safeSave("ModelContext+Routine deleteRoutineEvents")
    }
}
