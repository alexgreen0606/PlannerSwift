//
//  trip.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftData

extension ModelContext {

    func saveTripChanges(
        from draftTrip: DraftTrip,
        to sourceTrip: Trip?
    ) -> Trip? {
        guard let bounds = draftTrip.datestampBounds
        else {
            return nil
        }

        let sourceLocation = sourceTrip?.location
        let draftLocation = draftTrip.location

        let trip = sourceTrip ?? Trip()
        trip.title = draftTrip.title
        trip.startDatestamp = bounds.startDatestamp
        trip.endDatestamp = bounds.endDatestamp
        trip.hideRoutines = draftTrip.hideRoutines
        trip.location = draftTrip.location
        
        // TODO: what about old dates that are no longer in the trip? Undo changes?

        for datestamp in trip.sortedDatestamps {
            let planner = self.loadPlanner(for: datestamp)

            // Update each planner to match the trip's location.

            if let plannerLocation = planner.location {
                if plannerLocation.name == sourceLocation?.name {
                    // The planner has a custom location that matches the trip's previous location.
                    // Update the planner's location to the new value.
                    planner.location = draftLocation
                }
            } else {
                planner.location = draftLocation
            }

            // TODO: update the hideRoutines for each planner as well.
        }

        if trip.modelContext == nil {
            self.insert(trip)
        }

        self.safeSave("trip.saveTripChanges")

        return trip
    }

    func cancelTrip(_ trip: Trip) {

        let datestamps = trip.sortedDatestamps

        var plannerMap: [String: Planner] = [:]

        if let location = trip.location {
            // For every day with a matching location, reset it to nil.
            for datestamp in datestamps {
                let planner =
                    plannerMap[datestamp] ?? loadPlanner(for: datestamp)
                plannerMap[datestamp] = planner

                if planner.location == location {
                    planner.location = nil
                }
            }
        }

        if trip.hideRoutines {
            // Turn on routines for every day.
            for datestamp in datestamps {

                // TODO: hide the routines.
            }
        }
        
        self.delete(trip)

        self.safeSave("trip.cancelTrip")
    }

}
