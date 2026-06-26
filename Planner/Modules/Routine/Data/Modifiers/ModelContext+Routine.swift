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
        in sortedRoutineEvents: [RoutineEventContext],
        routine: Routine
    ) -> /// The ID of the new event.
        UUID?
    {
        let sortDate = generateRoutineEventSortDate(
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
    func getSortedRoutineEvents(
        for routine: Routine,
        reversed: Bool = false
    ) -> [RoutineEventContext] {
        do {
            let allRoutineEvents = try fetch(
                FetchDescriptor<RoutineEvent>(
                    predicate:
                        RoutineEvent.routineEvents(
                            for: routine
                        ),
                    sortBy: [
                        SortDescriptor(
                            \RoutineEvent.sortDate,
                            order: reversed ? .reverse : .forward
                        )
                    ]
                )
            )

            return allRoutineEvents.compactMap(\.routineEventContext)

        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine getSortedRoutineEvents: \(error)"
            )
        }

        return []
    }

    @MainActor
    func getRoutineEventVariant(
        for calendarItemExternalIdentifier: String
    ) -> RoutineEventVariant? {
        do {
            let matchingRoutineVariants = try fetch(
                FetchDescriptor<RoutineEventVariant>(
                    predicate: RoutineEventVariant.routineEventVariants(
                        for: calendarItemExternalIdentifier
                    )
                )
            )

            return matchingRoutineVariants.first
        } catch {
            assertionFailure(
                "ERROR ModelContext+Routine getRoutineEventVariant: \(error)"
            )
        }

        return nil
    }
    
    @MainActor
    func getRoutine(
        for weekdayRawValue: String
    ) -> Routine? {
        do {
            let matchingRoutines = try fetch(
                FetchDescriptor<Routine>(
                    predicate: Routine.routines(
                        for: weekdayRawValue
                    )
                )
            )
            
            return matchingRoutines.first
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
        sortedRoutineEvents: [RoutineEventContext],
        routine: Routine
    ) {
        let movedEvent = sortedRoutineEvents[from]

        guard let movedInstance = movedEvent.routineEvent(for: routine) else {
            return
        }

        movedInstance.sortDate =
            generateRoutineEventSortDate(
                at: to,
                in: sortedRoutineEvents,
                for: routine
            )

        // Update sort date version so that each routine event record re-positions itself in its planner.
        movedInstance.sortDateVersion += 0.1

        safeSave("ModelContext+Routine moveRoutineEvent")
    }

    @MainActor
    func bulkUpdateRoutineEventWeekdays(
        _ routineEvents: [RoutineEventContext],
        to destinationWeekdays: Set<Weekday>,
        sourceSortedRoutineEvents: [RoutineEventContext],
        ekEventStore: EKEventStore
    ) {
        guard !destinationWeekdays.isEmpty else { return }

        for routineEvent in routineEvents {
            updateRoutineEventContextWeekdays(
                routineEvent,
                with: destinationWeekdays,
                sourceSortedRoutineEvents: sourceSortedRoutineEvents,
                ekEventStore: ekEventStore
            )
        }

        safeSave("ModelContext+Routine bulkUpdateRoutineEventWeekdays")
    }

    // MARK: - DELETE

    @MainActor
    func deleteRoutineEvents(
        _ routineEvents: [RoutineEventContext],
        ekEventStore: EKEventStore,
    ) {
        for event in routineEvents {
            _ = deleteRoutineEventContext(
                event,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }

        safeSave("ModelContext+Routine deleteRoutineEvents")
    }
}
