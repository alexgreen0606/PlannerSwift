//
//  ModelContext+Cleanup.swift
//  Planner
//
//  Created by Alex Green on 3/20/26.
//

import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    @MainActor
    func deleteStaleData(minStartOfDay: DateInRegion) {
        let minDatestamp = minStartOfDay.datestamp
        let minDate = minStartOfDay.date

        do {
            // MARK: Delete locations that have no relationships.

            let orphanedLocations = try fetch(
                FetchDescriptor<Location>(
                    predicate: #Predicate<Location> {
                        $0.settings == nil
                    }
                )
            ).filter {
                $0.safeTrips.isEmpty
                    && $0.safePlanners.isEmpty
                    && $0.safePlannerEvents.isEmpty
            }

            for location in orphanedLocations {
                delete(location)
            }

            // MARK: Delete events that occurred before the cutoff date.

            let expiredEvents = try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate<PlannerEvent> { event in
                        if let ekEventContext = event.eKEventContext {
                            return ekEventContext.endDate <= minDate
                        } else if let time = event.time {
                            return time < minDate
                        } else if let datestamp = event.datestamp {
                            return datestamp < minDatestamp
                        } else {
                            return true
                        }
                    }
                )
            )

            for event in expiredEvents {
                delete(event)
            }

            // MARK: Delete planners that occurred before the cutoff date.

            let expiredPlanners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> {
                        $0.datestamp < minDatestamp && $0.trip == nil
                    }
                )
            )

            for planner in expiredPlanners {
                delete(planner)
            }

            // MARK: Delete trips that ended before the cutoff date.

            let expiredTrips = try fetch(FetchDescriptor<Trip>()).filter {
                $0.lastDatestamp < minDatestamp
            }

            for trip in expiredTrips {
                delete(trip)
            }

        } catch {
            assertionFailure("ModelContext+Cleanup deleteStaleData: \(error)")
        }

        // Note: DO NOT save the context here.
        // This will be done in the parent that invoked this function.
    }
}
