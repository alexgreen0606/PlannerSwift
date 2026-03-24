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
        guard let bounds = draftTrip.datestampBounds
        else {
            return nil
        }

        // Tracks any days that were removed from the trip.
        var staleDatestamps = Set(sourceTrip?.sortedDatestamps ?? [])

        let sourceLocation = sourceTrip?.location
        let draftLocation = draftTrip.location

        let trip = sourceTrip ?? Trip()
        trip.title = draftTrip.title
        trip.startDatestamp = bounds.startDatestamp
        trip.endDatestamp = bounds.endDatestamp
        trip.hideRoutines = draftTrip.hideRoutines
        trip.location = draftTrip.location

        for datestamp in trip.sortedDatestamps {
            staleDatestamps.remove(datestamp)

            let planner = self.loadPlanner(for: datestamp)

            // Update each day to match the trip's location.
            if let plannerLocation = planner.location {
                // If the day has a custom location DIFFERENT from the trip's, leave it be.
                if plannerLocation.name == sourceLocation?.name {
                    planner.location = draftLocation
                }
            } else {
                planner.location = draftLocation
            }

            // TODO: update the hideRoutines for each planner as well.
        }

        // Reset the state of any days that were removed from the trip.
        for datestamp in staleDatestamps {
            let planner = self.loadPlanner(for: datestamp)

            // Revert the day's location ONLY IF it matches the trip's.
            if let plannerLocation = planner.location,
                plannerLocation.name == sourceLocation?.name
            {
                planner.location = nil
            }

            // TODO: revert hideRoutines when that logic exists
        }

        if trip.modelContext == nil {
            self.insert(trip)
        }

        self.safeSave("trip.saveTripChanges")

        return trip
    }

    @MainActor
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
