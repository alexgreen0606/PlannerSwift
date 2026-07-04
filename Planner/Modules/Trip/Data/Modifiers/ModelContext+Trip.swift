//
//  ModelContext+Trip.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import Foundation
import SwiftData

extension ModelContext {
    // MARK: - READ

    func getSortedTrips(onOrBefore datestamp: String)
        -> [Trip]
    {
        do {
            return try fetch(
                FetchDescriptor<Trip>(
                    predicate: Trip.trips(onOrBefore: datestamp),
                    sortBy: [
                        SortDescriptor(\Trip.firstDatestamp)
                    ]
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+Trip getSortedTrips: \(error)"
            )
        }

        return []
    }

    @MainActor
    func getExistingTripDatestamps() -> Set<String> {
        do {
            let existingTrips = try fetch(
                FetchDescriptor<Trip>()
            )

            return Set(
                existingTrips
                    .flatMap(\.safePlanners)
                    .map(\.datestamp)
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+Trip getExistingTripDatestamps: \(error)"
            )
        }

        return []
    }

    // MARK: - UPDATE

    @MainActor
    func updateTrip(
        _ sourceTrip: Trip?,
        with draftTrip: DraftTrip,
        plannerService: PlannerService
    ) -> Trip {

        let trip = sourceTrip ?? Trip()

        trip.title = draftTrip.title.trimmed
        trip.location = draftTrip.location
        trip.excludeRoutines = draftTrip.excludeRoutines

        let existingPlanners = Dictionary(
            uniqueKeysWithValues: trip.safePlanners.map { ($0.datestamp, $0) }
        )

        let existingDatestamps = Set(existingPlanners.keys)
        let newDatestamps = Set(draftTrip.datestamps)

        let datestampsToAdd = newDatestamps.subtracting(existingDatestamps)
        let datestampsToRemove = existingDatestamps.subtracting(newDatestamps)

        // Add new planners to the trip.
        for datestamp in datestampsToAdd {
            let planner = getPlanner(for: datestamp)
            trip.planners.safeAppend(planner)
            planner.trip = trip
        }

        // Remove stale planners from the trip.
        for datestamp in datestampsToRemove {
            guard let planner = existingPlanners[datestamp] else { continue }

            trip.planners?.removeAll { $0 === planner }
            planner.trip = nil
        }

        let sortedPlanners = trip.sortedPlanners

        trip.firstDatestamp = sortedPlanners.first?.datestamp ?? ""
        trip.lastDatestamp = sortedPlanners.last?.datestamp ?? ""

        insertIfNeeded(trip)
        safeSave("ModelContext+Trip updateTrip")

        plannerService.handleTripChange()

        return trip
    }
}
