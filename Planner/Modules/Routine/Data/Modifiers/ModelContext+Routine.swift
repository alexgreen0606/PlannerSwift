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

    // MARK: - CREATE

    @MainActor
    func createRoutineEvent(
        at index: Int,
        in sortedRoutineEvents: [RoutineEvent],
        on weekday: Weekday
    ) -> /// The ID of the new event.
        UUID?
    {
        let sortDate = generateRoutineEventSortDate(
            at: index,
            in: sortedRoutineEvents,
            on: weekday
        )

        let routineEvent = RoutineEvent()
        let instance = RoutineEventWeekdayInstance(
            weekday: weekday,
            sortDate: sortDate
        )

        routineEvent.weekdayInstances?.append(instance)
        instance.routineEvent = routineEvent

        insert(routineEvent)

        // Note: Don't save the context here.
        // It can cause flickered duplicates in the list.

        return routineEvent.stableId
    }

    // MARK: - READ

    @MainActor
    func getSortedRoutineEvents(
        for weekday: Weekday,
        reversed: Bool = false
    ) -> [RoutineEvent] {
        do {
            let allRoutineEvents = try fetch(
                FetchDescriptor<RoutineEventWeekdayInstance>(
                    predicate:
                        RoutineEventWeekdayInstance.instances(
                            for: weekday
                        ),
                    sortBy: [
                        SortDescriptor(
                            \RoutineEventWeekdayInstance.sortDate,
                            order: reversed ? .reverse : .forward
                        )
                    ]
                )
            )

            return allRoutineEvents.compactMap(\.routineEvent)

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
                    predicate: RoutineEventVariant.variants(
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
                on: weekday
            )

        // Clear synced planner events so that each event re-positions itself in its planner.
        movedEvent.syncedSortDatePlannerEventIds.removeAll()

        safeSave("ModelContext+Routine moveRoutineEvent")
    }

    @MainActor
    func bulkUpdateRoutineEventWeekdays(
        _ routineEvents: [RoutineEvent],
        to destinationWeekdays: Set<Weekday>,
        sourceWeekday _: Weekday,
        sourceSortedRoutineEvents: [RoutineEvent],
        ekEventStore: EKEventStore
    ) {
        guard !destinationWeekdays.isEmpty else { return }

        for routineEvent in routineEvents {
            updateRoutineEventWeekdays(
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
        _ routineEvents: [RoutineEvent],
        ekEventStore: EKEventStore,
    ) {
        for event in routineEvents {
            _ = deleteRoutineEvent(
                event,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }

        safeSave("ModelContext+Routine deleteRoutineEvents")
    }
}
