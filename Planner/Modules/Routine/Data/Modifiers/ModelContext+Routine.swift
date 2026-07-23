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

    // MARK: - ENSURE / DEDUPLICATION

    @MainActor
    func ensureRoutines() {
        do {
            let existingRoutines = try fetch(
                FetchDescriptor<Routine>()
            )

            let routinesByWeekday = Dictionary(
                grouping: existingRoutines,
                by: \.weekdayRawValue
            )

            var didModify = false

            for weekday in Weekday.allCases {
                let routines = routinesByWeekday[weekday.rawValue] ?? []

                switch routines.count {
                case 0:
                    insert(
                        Routine(weekdayRawValue: weekday.rawValue)
                    )
                    
                    didModify = true

                    break

                case 1:
                    break

                default:
                    deduplicateRoutine(routines: routines)
                    
                    didModify = true
                }
            }

            if didModify {
                safeSave("ModelContext+Routine ensureRoutines")
            }
        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine ensureRoutines: \(error)"
            )
        }
    }

    @MainActor
    private func deduplicateRoutine(
        routines: [Routine]
    ) {
        guard let merged = routines.first else {
            return
        }

        for routine in routines.dropFirst() {
            // Merge routine events.
            for routineEvent in routine.safeRoutineEvents {
                merged.routineEvents.safeAppend(routineEvent)
                routineEvent.routine = merged
            }

            // Merge planners.
            for planner in routine.safePlanners {
                merged.planners.safeAppend(planner)
                planner.routine = merged
            }

            routine.routineEvents = nil
            routine.planners = nil

            delete(routine)
        }
    }

    // MARK: - CREATE

    @MainActor
    func createRoutineEventContext(
        at index: Int,
        in sortedRoutineEvents: [RoutineEvent],
        routine: Routine
    ) -> /// The ID of the new event.
        UUID?
    {
        let sortDate = safeGenerateRoutineEventSortDate(
            at: index,
            in: sortedRoutineEvents,
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
        sortedRoutineEvents: [RoutineEvent],
        routine: Routine
    ) {
        let movedEvent = sortedRoutineEvents[from]

        movedEvent.sortDate =
            safeGenerateRoutineEventSortDate(
                at: to,
                in: sortedRoutineEvents,
                for: routine
            )

        // Update sort date version so that each routine event record re-positions itself in its planner.
        movedEvent.sortDateVersion += 0.1

        safeSave("ModelContext+Routine moveRoutineEvent")
    }

    @MainActor
    func bulkUpdateRoutineEventWeekdays(
        _ routineEventContexts: [RoutineEventContext],
        to destinationWeekdays: Set<Weekday>,
        sourceSortedRoutineEvents: [RoutineEvent],
        todayStartOfDay: DateInRegion,
        ekEventStore: EKEventStore
    ) {
        guard !destinationWeekdays.isEmpty else { return }

        for routineEventContext in routineEventContexts {
            updateRoutineEventContextWeekdays(
                routineEventContext,
                with: destinationWeekdays,
                sourceSortedRoutineEvents: sourceSortedRoutineEvents,
                todayStartOfDay: todayStartOfDay,
                ekEventStore: ekEventStore
            )
        }

        safeSave("ModelContext+Routine bulkUpdateRoutineEventWeekdays")
    }

    // MARK: - DELETE

    @MainActor
    func deleteRoutineEventContexts(
        _ routineEventContexts: [RoutineEventContext],
        todayStartOfDay: DateInRegion,
        ekEventStore: EKEventStore,
    ) {
        var externalCalendarIds: Set<String> = []

        for routineEventContext in routineEventContexts {
            externalCalendarIds.formUnion(
                deleteRoutineEventContext(
                    routineEventContext,
                    todayStartOfDay: todayStartOfDay,
                    inLoop: true
                )
            )
        }

        // Delete stale calendar events and their records from today onward.
        if !externalCalendarIds.isEmpty {
            deleteCalendarEvents(
                externalIds: externalCalendarIds,
                onOrAfter: todayStartOfDay,
                ekEventStore: ekEventStore
            )
        }

        safeSave("ModelContext+Routine deleteRoutineEvents")
    }

    @MainActor
    func deleteCalendarEvents(
        externalIds: Set<String>,
        onOrAfter: DateInRegion,
        ekEventStore: EKEventStore
    ) {
        let deletedIds = ekEventStore.attemptDeleteEvents(
            externalIdentifiers: externalIds,
            onOrAfter: onOrAfter.date
        )

        if !deletedIds.isEmpty {
            deleteCalendarRecords(
                externalIds: deletedIds,
                onOrAfter: onOrAfter.date
            )
        }
    }
}
