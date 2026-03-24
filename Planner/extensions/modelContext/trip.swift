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
    func saveTripChanges(
        from draftTrip: DraftTrip,
        to sourceTrip: Trip?
    ) -> Trip? {
            
            var sourcePlanners: [String: Planner] = Dictionary(
                uniqueKeysWithValues: (sourceTrip?.planners ?? []).map { planner in
                    (planner.datestamp, planner)
                }
            )
            
            let trip = sourceTrip ?? Trip()
            trip.title = draftTrip.title
            trip.hideRoutines = draftTrip.hideRoutines
            trip.location = draftTrip.location
            
            // Add any new planners to this trip.
            for datestamp in draftTrip.datestamps {
                
                if sourcePlanners[datestamp] != nil {
                    sourcePlanners.removeValue(forKey: datestamp)
                    continue
                }
                
                let newPlanner = self.loadPlanner(for: datestamp)
                trip.planners.append(newPlanner)
                newPlanner.trip = trip
            }
            
            // Remove any stale planners from this trip.
            for (_, stalePlanner) in sourcePlanners {
                if let index = trip.planners.firstIndex(where: {
                    $0 === stalePlanner
                }) {
                    trip.planners.remove(at: index)
                }
                stalePlanner.trip = nil
            }
            
            if trip.modelContext == nil {
                self.insert(trip)
            }
            
            self.safeSave("trip.saveTripChanges")
            
            return trip
    }

    @MainActor
    func cancelTrip(_ trip: Trip) {
        self.delete(trip)
        self.safeSave("trip.cancelTrip")
    }

}
