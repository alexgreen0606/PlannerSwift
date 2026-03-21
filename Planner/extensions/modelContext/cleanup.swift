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

        do {

            // Delete locations that haven't been selected since the cutoff date.

            let oldLocations = try self.fetch(
                FetchDescriptor<Location>(
                    predicate: #Predicate<Location> {
                        $0.selectedOn < date
                    }
                )
            )

            for location in oldLocations {
                self.delete(location)
            }

            // Delete events that occurred before the cutoff date.

            let oldEvents = try self.fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: #Predicate<PlannerEvent> {
                        $0.date < date
                    }
                )
            )

            for event in oldEvents {
                self.delete(event)
            }

            // Delete planners that occurred before the cutoff date.

            let datestamp = DateInRegion(date, region: .local).datestamp

            let oldPlanners = try self.fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> {
                        $0.datestamp < datestamp
                    }
                )
            )

            for planner in oldPlanners {
                self.delete(planner)
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
