//
//  trip.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftData

// Clean

extension ModelContext {

    @MainActor
    func updateTrip(
        from draftTrip: DraftTrip,
        to sourceTrip: Trip?
    ) -> Trip? {

        var resultTrip: Trip?

        do {
            try self.transaction {

                var sourcePlanners: [String: Planner] = Dictionary(
                    uniqueKeysWithValues: (sourceTrip?.planners ?? []).map {
                        planner in
                        (planner.datestamp, planner)
                    }
                )

                let trip = sourceTrip ?? Trip()
                trip.title = draftTrip.title
                trip.excludeRoutines = draftTrip.excludeRoutines
                trip.location = draftTrip.location

                // Add any new planners to this trip.
                for datestamp in draftTrip.datestamps {

                    if sourcePlanners[datestamp] != nil {
                        sourcePlanners.removeValue(forKey: datestamp)
                        continue
                    }

                    let newPlanner = self.getPlanner(for: datestamp)
                    trip.planners?.append(newPlanner)
                    newPlanner.trip = trip
                }

                // Remove any stale planners from this trip.
                for (_, stalePlanner) in sourcePlanners {
                    if let index = trip.safePlanners.firstIndex(where: {
                        $0 === stalePlanner
                    }) {
                        trip.planners?.remove(at: index)
                    }
                    stalePlanner.trip = nil
                }

                self.insertIfNeeded(trip)

                resultTrip = trip
            }
        } catch {
            assertionFailure(
                "ERROR checklistItem.updateTrip: \(error)"
            )
            return nil
        }

        self.safeSave("trip.updateTrip")

        return resultTrip
    }

}
