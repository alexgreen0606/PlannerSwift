//
//  ModelContext+Trip.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import Foundation
import SwiftData

extension ModelContext {
    func getExistingTripDatestamps() -> Set<String> {
        do {
            let existingTrips = try fetch(
                FetchDescriptor<Trip>()
            )

            return existingTrips.reduce(into: Set<String>()) {
                result,
                trip in
                result.formUnion(trip.safePlanners.map(\.datestamp))
            }
        } catch {
            return []
        }
    }

    @MainActor
    func updateTrip(
        from draftTrip: DraftTrip,
        to sourceTrip: Trip?,
        plannerSyncService: PlannerSyncService
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
            plannerSyncService.invalidatePlannerRoutine(
                datestamp: datestamp
            )

            if let sourcePlanner = sourcePlanners[datestamp] {
                sourcePlanners.removeValue(forKey: datestamp)
                continue
            }

            let newPlanner = getPlanner(for: datestamp)
            trip.planners?.append(newPlanner)
            newPlanner.trip = trip
            
            // TODO: make sure this planner is invalidated so it refreshes.

        }

        // Remove any stale planners from this trip.
        for (_, stalePlanner) in sourcePlanners {
            // Re-sync the planner routine.
            plannerSyncService.invalidatePlannerRoutine(
                datestamp: stalePlanner.datestamp
            )

            if let index = trip.safePlanners.firstIndex(where: {
                $0 === stalePlanner
            }) {
                trip.planners?.remove(at: index)
            }

            stalePlanner.trip = nil
        }

        trip.firstDatestamp = trip.sortedPlanners.first?.datestamp ?? ""
        trip.lastDatestamp = trip.sortedPlanners.last?.datestamp ?? ""

        insertIfNeeded(trip)
        safeSave("trip.updateTrip")

        plannerSyncService.beginSync()

        return trip
    }
}
