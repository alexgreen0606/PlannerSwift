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
    func deleteStorageRecords(
        olderThan date: Date
    ) {
        let datestamp = DateInRegion(date, region: .local).datestamp

        do {

            // MARK: Delete routine event variants that have no parents.

            let orphanVariants = try self.fetch(
                FetchDescriptor<RoutineEventVariant>()
            ).filter {
                $0.routineEvent == nil
                    && $0.plannerEvent == nil
                    && $0.planner == nil
            }

            for variant in orphanVariants {
                self.delete(variant)
            }

            // MARK: Delete locations that have no parents.

            let orphanLocations = try self.fetch(
                FetchDescriptor<Location>(
                    predicate: #Predicate<Location> {
                        $0.plannerSettings == nil
                    }
                )
            ).filter {
                $0.safeTrips.isEmpty
                    && $0.safePlanners.isEmpty
                    && $0.safeEvents.isEmpty
            }

            for location in orphanLocations {
                self.delete(location)
            }

            // MARK: Delete events that occurred before the cutoff date.
            
            let expirationDatestamp = date.datestamp

            let expiredEvents = try self.fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate<PlannerEvent> { event in
                        if let time = event.time {
                            return time < date
                        } else if let datestamp = event.datestamp {
                            return datestamp < expirationDatestamp
                        } else {
                            return false
                        }
                    }
                )
            )

            for event in expiredEvents {
                self.delete(event)
            }

            // MARK: Delete planners that occurred before the cutoff date.

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

            // MARK: Delete trips that ended before the cutoff date.

            let trips = try self.fetch(FetchDescriptor<Trip>())
            let expiredTrips = trips.filter { trip in
                guard
                    let last = trip.sortedPlanners.last
                else {
                    return true
                }
                return last.datestamp < datestamp
            }

            for trip in expiredTrips {
                self.delete(trip)
            }

        } catch {
            assertionFailure("cleanup.deleteStorageRecords: \(error)")
        }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

    @MainActor
    func deleteCanceledPlans(for todaystamp: String, settings: PlannerSettings)
    {
        let planner = getPlanner(for: todaystamp)

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
