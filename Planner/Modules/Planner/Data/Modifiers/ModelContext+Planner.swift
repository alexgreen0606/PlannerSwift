//
//  ModelContext+Planner.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    // MARK: - ENSURE

    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) {
        if planners.first != nil {
            return
        }

        _ = createPlanner(for: datestamp)
    }

    // MARK: - CREATE

    private func createPlanner(for datestamp: String, skipSave: Bool = false)
        -> Planner
    {
        guard let routine = getRoutine(for: datestamp.weekday) else {
            // TODO: is this bad?
            fatalError()
        }

        let planner = Planner(datestamp: datestamp, routine: routine)

        insert(planner)

        if !skipSave {
            safeSave("ModelContext+Planner createPlanner")
        }

        return planner
    }

    // MARK: - READ

    @MainActor
    func getPlanner(
        for datestamp: String
    ) -> Planner {
        do {
            let planners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: Planner.planners(datestamp: datestamp)
                )
            )

            return planners.first ?? createPlanner(for: datestamp)
        } catch {
            return createPlanner(for: datestamp)
        }
    }

    /// Gathers all data needed to eager-build a list of planners.
    @MainActor
    func getBulkPlannerSyncContexts(
        for datestamps: Set<String>,
        settings: Settings
    ) -> [PlannerSyncContext] {
        do {
            // Load in planners that already exist in storage.

            let existingPlanners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: Planner.planners(datestamps: datestamps)
                )
            )

            var allPlanners = existingPlanners

            // Create new planners that don't exist yet.

            for datestamp in datestamps
            where !allPlanners.contains(where: { $0.datestamp == datestamp }) {
                allPlanners.append(
                    createPlanner(for: datestamp, skipSave: true)
                )
            }

            // Build a list of data needed to build each planner.

            var contexts: [PlannerSyncContext] = []

            for planner in allPlanners {
                contexts.append(
                    PlannerSyncContext(
                        planner: planner,
                        startOfDay: planner.startOfDay(settings: settings)
                    )
                )
            }

            return contexts
        } catch {
            return []
        }
    }

    /// Fetches the start of days for all planners that can hold an event with the given absolute point in time.
    /// When no time is given, the datestamp will be used to load that planner and calculate it's start of day.
    @MainActor
    func getSortedPlannerStartOfDays(
        for time: Date?,
        endTime: Date? = nil,
        datestamp: String? = nil,
        settings: Settings
    ) -> [DateInRegion] {
        guard let time else {
            guard let datestamp else {
                return []
            }

            let planner = getPlanner(for: datestamp)

            // Event has no time. Return the start of day for the event's assigned planner.
            return [
                planner.startOfDay(settings: settings)
            ]
        }

        let sortedPossibleDatestamps =
            getSortedPossibleDatestamps(for: time, ending: endTime)

        var sortedStartOfDays: [DateInRegion] = []

        // Gather all planner start of days that contain the event.
        for datestamp in sortedPossibleDatestamps {
            let planner = getPlanner(for: datestamp)

            let startOfDay = planner.startOfDay(settings: settings)

            let eventExistsInPlanner = {
                if let endTime,
                    startOfDay.includes(startTime: time, endTime: endTime)
                {
                    return true
                }

                return time.belongsToPlanner(startOfDay: startOfDay)
            }()

            if eventExistsInPlanner {
                sortedStartOfDays.append(startOfDay)
            }
        }

        return sortedStartOfDays
    }

    @MainActor
    func getUpperSortDate(for startOfDay: DateInRegion) -> Date {
        let listEvents = getSortedListEvents(on: startOfDay)
        return generatePlannerEventSortDate(
            at: 0,
            in: listEvents,
            startOfDay: startOfDay
        )
    }

    // MARK: - UPDATE

    @MainActor
    func updatePlannerLocation(
        for planner: Planner,
        to newLocation: Location?
    ) {
        planner.location = newLocation
        safeSave("ModelContext+Planner updatePlannerLocation")
    }

    @MainActor
    func togglePlannerRoutineExclusion(
        for planner: Planner,
        plannerService: PlannerService
    ) {
        planner.excludeRoutine = !planner.safeExcludeRoutine

        if let trip = planner.trip,
            trip.excludeRoutines == planner.excludeRoutine
        {
            // Revert flag back to nil so it inherits the exclusion state from the trip.
            planner.excludeRoutine = nil
        }

        safeSave("ModelContext+Planner togglePlannerRoutineExclusion")

        // Sync the planner's routine.
        plannerService.syncPlannerRoutine(
            planner: planner
        )
    }
}
