//
//  planner.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

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

        let _ = self.createPlanner(for: datestamp)
    }

    // MARK: - CREATE

    private func createPlanner(for datestamp: String) -> Planner {
        let planner = Planner(datestamp: datestamp, location: nil)

        insert(planner)
        self.safeSave("planner.createPlanner")

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

            return planners.first ?? self.createPlanner(for: datestamp)
        } catch {
            return self.createPlanner(for: datestamp)
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
        let storageEvents = self.getSortedStorageEvents(for: plannerDay)
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
        self.safeSave("planner.updatePlannerLocation")
    }

    @MainActor
    func togglePlannerRoutineExclusion(
        for planner: Planner,
        plannerEvents: [PlannerEvent],
        plannerBuildManager: PlannerBuildManager
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
        plannerBuildManager.rebuildDatestampRoutine(
            planner.datestamp
        )
    }

}
