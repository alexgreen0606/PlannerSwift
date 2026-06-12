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
        let planner = Planner(datestamp: datestamp)

        insert(planner)

        if !skipSave {
            safeSave("ModelContext+Planner.createPlanner")
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
                    predicate: #Predicate<Planner> { planner in
                        planner.datestamp == datestamp
                    }
                )
            )

            return planners.first ?? createPlanner(for: datestamp)
        } catch {
            return createPlanner(for: datestamp)
        }
    }

    // TODO: what if a trip goes so far back that its planners are out of range? I Shouldnt delete the planners then.

    /// Gathers all data needed to eager-build a list of planners.
    @MainActor
    func getBulkPlannerBuildContexts(
        for datestamps: Set<String>,
        settings: PlannerSettings
    ) -> [PlannerBuildContext] {
        do {
            // Load in planners that already exist in storage.

            let existingPlanners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> { planner in
                        datestamps.contains(planner.datestamp)
                    }
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

            var contexts: [PlannerBuildContext] = []

            for planner in allPlanners {
                contexts.append(
                    PlannerBuildContext(
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
        settings: PlannerSettings
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
        let storageEvents = getSortedPlannerEvents(on: startOfDay)
        return generateSortDate(
            at: 0,
            in: storageEvents,
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
        safeSave("ModelContext+Planner.updatePlannerLocation")
    }

    @MainActor
    func togglePlannerRoutineExclusion(
        for planner: Planner,
        plannerSyncService: PlannerSyncService
    ) {
        planner.excludeRoutine = !planner.safeExcludeRoutine

        if let trip = planner.trip,
            trip.excludeRoutines == planner.excludeRoutine
        {
            // Revert flag back to nil so it inherits the exclusion state from the trip.
            planner.excludeRoutine = nil
        }

        safeSave("ModelContext+Planner.togglePlannerRoutineExclusion")

        // Sync the planner's routine events.
        plannerSyncService.syncPlannerRoutine(
            datestamp: planner.datestamp
        )
    }
}
