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
    func deleteStaleData(cutoffDate: Date) {
        let cutoffDatestamp = DateInRegion(cutoffDate, region: .local).datestamp

        do {
            // MARK: Delete routine event variants that have no relationships.

            let orphanedRoutineEventVariants = try fetch(
                FetchDescriptor<RoutineEventVariant>()
            ).filter {
                $0.routineEvent == nil
                    && $0.plannerEvent == nil
                    && $0.planner == nil
            }

            for variant in orphanedRoutineEventVariants {
                delete(variant)
            }

            // MARK: Delete locations that have no relationships.

            let orphanedLocations = try fetch(
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

            for location in orphanedLocations {
                delete(location)
            }

            // MARK: Delete events that occurred before the cutoff date.

            let expiredEvents = try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate<PlannerEvent> { event in
                        if let time = event.time {
                            return time < cutoffDate // TODO: what if it's a calendar event and the end date still hasn't happened yet?
                        } else if let datestamp = event.datestamp {
                            return datestamp < cutoffDatestamp
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
                        $0.datestamp < cutoffDatestamp
                    }
                )
            )

            for planner in expiredPlanners {
                delete(planner)
            }

            // MARK: Delete trips that ended before the cutoff date.

            let expiredTrips = try fetch(FetchDescriptor<Trip>()).filter {
                $0.lastDatestamp < cutoffDatestamp
            }

            for trip in expiredTrips {
                delete(trip)
            }

        } catch {
            assertionFailure("ModelContext+Cleanup.deleteStaleData: \(error)")
        }

        // Note: DO NOT save the context here.
        // This will be done in the parent that invoked this function.
    }
}
