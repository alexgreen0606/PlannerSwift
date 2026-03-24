//
//  cleanup.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    @MainActor
    func deleteOldData(
        before date: Date
    ) {
        let datestamp = DateInRegion(date, region: .local).datestamp

        do {

            // Delete locations that have no parents.

            let orphanLocations = try self.fetch(
                FetchDescriptor<Location>(
                    predicate: #Predicate<Location> {
                        $0.trips.isEmpty
                            && $0.planners.isEmpty
                            && $0.events.isEmpty
                            && $0.plannerSettings == nil
                    }
                )
            )

            for location in orphanLocations {
                self.delete(location)
            }

            // Delete events that occurred before the cutoff date.

            let expiredEvents = try self.fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate<PlannerEvent> {
                        $0.date < date
                    }
                )
            )

            for event in expiredEvents {
                self.delete(event)
            }

            // Delete planners that occurred before the cutoff date.

            let expiredPlanners = try self.fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> {
                        $0.datestamp < datestamp
                    }
                )
            )

            for planner in expiredPlanners {
                self.delete(planner)
            }

            // Delete trips that ended before the cutoff date.

            let expiredTrips = try self.fetch(
                FetchDescriptor<Trip>(
                    predicate: #Predicate<Trip> {
                        if let lastDatestamp = $0.planners.last?.datestamp {
                            return lastDatestamp < datestamp
                        } else {
                            return true
                        }
                    }
                )
            )

            for trip in expiredTrips {
                self.delete(trip)
            }

        } catch {
            assertionFailure("cleanup.deleteOldData: \(error)")
        }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

    func deleteCanceledPlans(for todaystamp: String, settings: PlannerSettings)
    {
        let planner = loadPlanner(for: todaystamp)

        guard
            let plannerDay = todaystamp.startOfDay(
                in: planner.region(settings: settings)
            )
        else {
            return
        }

        let events = self.getSortedStorageEvents(for: plannerDay)

        for event in events where event.isCanceled {
            self.delete(event)
        }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

}
