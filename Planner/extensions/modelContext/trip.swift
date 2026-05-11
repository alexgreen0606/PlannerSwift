//
//  trip.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import Foundation
import SwiftData

extension ModelContext {

    @MainActor
    func updateTrip(
        from draftTrip: DraftTrip,
        to sourceTrip: Trip?,
        plannerBuildManager: PlannerBuildManager
    ) -> Trip {

        var sourcePlanners: [String: Planner] = Dictionary(
            uniqueKeysWithValues: (sourceTrip?.planners ?? []).map {
                planner in
                (planner.datestamp, planner)
            }
        )

        let trip = sourceTrip ?? Trip()
        trip.title = draftTrip.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        trip.excludeRoutines = draftTrip.excludeRoutines
        trip.location = draftTrip.location

        // Add any new planners to this trip.
        for datestamp in draftTrip.datestamps {

            // Invalidate the planner routine.
            plannerBuildManager.invalidateDatestampRoutine(
                datestamp
            )

            if let sourcePlanner = sourcePlanners[datestamp] {
                sourcePlanners.removeValue(forKey: datestamp)

                // Clear any of the planner's routine variants if they are now excluded.
                if sourcePlanner.safeExcludeRoutine {
                    for variant in sourcePlanner.safeRoutineEventVariants {
                        delete(variant)
                    }
                    sourcePlanner.routineEventVariants = []
                }

                continue
            }

            let newPlanner = getPlanner(for: datestamp)
            trip.planners?.append(newPlanner)
            newPlanner.trip = trip

            // Clear any of the planner's routine variants if they are now excluded.
            if newPlanner.safeExcludeRoutine {
                for variant in newPlanner.safeRoutineEventVariants {
                    delete(variant)
                }
                newPlanner.routineEventVariants = []
            }
        }

        // Remove any stale planners from this trip.
        for (_, stalePlanner) in sourcePlanners {

            // Re-sync the planner routine.
            plannerBuildManager.invalidateDatestampRoutine(
                stalePlanner.datestamp
            )

            if let index = trip.safePlanners.firstIndex(where: {
                $0 === stalePlanner
            }) {
                trip.planners?.remove(at: index)
            }
            
            stalePlanner.trip = nil
        }

        insertIfNeeded(trip)
        safeSave("trip.updateTrip")

        plannerBuildManager.beginRebuild()

        return trip
    }

}
