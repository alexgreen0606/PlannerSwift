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

struct FullPlannerContext {
    let planner: Planner
    let plannerDay: DateInRegion
    let sortedPlannerEvents: [PlannerEvent]
}

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
        let planner = Planner(datestamp: datestamp, location: nil)

        insert(planner)

        if !skipSave {
            safeSave("planner.createPlanner")
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

    @MainActor
    func getBulkPlannerContexts(
        for datestamps: Set<String>,
        settings: PlannerSettings
    ) -> [FullPlannerContext] {
        do {
            let existingPlanners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> { planner in
                        datestamps.contains(planner.datestamp)
                    }
                )
            )

            var allPlanners = existingPlanners

            for datestamp in datestamps
            where !allPlanners.contains(where: { $0.datestamp == datestamp }) {
                allPlanners.append(
                    createPlanner(for: datestamp, skipSave: true)
                )
            }

            var fullPlannerContexts: [FullPlannerContext] = []

            for planner in allPlanners {
                guard
                    let plannerDay = planner.datestamp.startOfDay(
                        in: planner.region(settings: settings)
                    )
                else {
                    continue
                }

                let sortedEvents = getSortedStorageEvents(for: plannerDay)

                fullPlannerContexts.append(
                    FullPlannerContext(
                        planner: planner,
                        plannerDay: plannerDay,
                        sortedPlannerEvents: sortedEvents
                    )
                )
            }

            return fullPlannerContexts
        } catch {
            return []
        }
    }

    @MainActor
    func getEarliestPlannerDay(
        for time: Date?,
        datestamp: String? = nil,
        settings: PlannerSettings
    ) -> DateInRegion? {
        guard let time else {
            guard let datestamp else {
                return nil
            }

            let planner = getPlanner(for: datestamp)
            guard
                let plannerDay = planner.datestamp.startOfDay(
                    in: planner.region(settings: settings)
                )
            else {
                return nil
            }

            // Return the planner day for the untimed event.
            return plannerDay
        }

        let sortedPossibleDatestamps =
            getSortedPossibleDatestamps(for: time)

        for datestamp in sortedPossibleDatestamps {
            let planner = getPlanner(for: datestamp)
            guard
                let plannerDay = planner.datestamp.startOfDay(
                    in: planner.region(settings: settings)
                )
            else {
                continue
            }

            if time.belongsTo(plannerDay) {
                return plannerDay
            }
        }

        // Date does not belong to any planner.
        return nil
    }

    @MainActor
    func getUpperSortDate(for plannerDay: DateInRegion) -> Date {
        let storageEvents = getSortedStorageEvents(for: plannerDay)
        return generateSortDate(
            at: 0,
            in: storageEvents,
            plannerDay: plannerDay
        )
    }

    // MARK: - UPDATE

    @MainActor
    func updatePlannerLocation(
        for planner: Planner,
        to newLocation: Location?
    ) {
        planner.location = newLocation
        safeSave("planner.updatePlannerLocation")
    }

    @MainActor
    func togglePlannerRoutineExclusion(
        for planner: Planner,
        PlannerSyncStore: PlannerSyncService
    ) {
        planner.excludeRoutine = !planner.safeExcludeRoutine

        if let trip = planner.trip,
            trip.excludeRoutines == planner.excludeRoutine
        {
            // Revert flag back to nil so it inherits from the trip.
            planner.excludeRoutine = nil
        }

        safeSave("planner.togglePlannerRoutineExclusion")

        // Re-sync the planner's routine events.
        PlannerSyncStore.syncPlannerRoutine(
            datestamp: planner.datestamp
        )
    }
}
