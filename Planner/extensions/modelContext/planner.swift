//
//  planner.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

extension ModelContext {

    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) {
        if planners.first != nil {
            return
        }

        let _ = self.createPlanner(for: datestamp)
    }

    @MainActor
    func loadPlanner(
        for datestamp: String
    ) -> Planner {
        do {
            let planners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> { planner in
                        planner.datestamp == datestamp
                    }
                )
            )

            return planners.first ?? self.createPlanner(for: datestamp)
        } catch {
            return self.createPlanner(for: datestamp)
        }
    }

    // MARK: - Data Modifiers

    @MainActor
    func updatePlannerLocation(
        for planner: Planner,
        to newLocation: Location?,
        settings: PlannerSettings,
        storageEvents: [PlannerEvent]
    ) {

        let newRegion = newLocation?.region ?? settings.homeRegion

        guard let newStartOfDay = planner.datestamp.startOfDay(in: newRegion)
        else {
            assertionFailure(
                "ERROR planner.updateLocation: Could not create new startOfDay for \(planner.datestamp)"
            )
            return
        }

        planner.location = newLocation

        // Set all untimed events' dates to the start of day in the planner's new location.
        for event in storageEvents where !event.hasTime {
            event.date = newStartOfDay.date
        }

        self.safeSave("planner.updatePlannerLocation")
    }

    @MainActor
    func deleteOldPlanners(
        from planners: [Planner],
        before cutoffDate: Date
    ) {

        let cutoffDatestamp = cutoffDate.toFormat("yyyy-MM-dd")

        // TODO: predicate this
        for planner in planners {
            if planner.datestamp < cutoffDatestamp {
                print("Deleting planner: \(planner.datestamp)")
                delete(planner)
            }
        }

        // TODO: delete planner events as well

        // Note: Don't save the context.
        // This is part of a larger pipeline.
    }

    @MainActor
    func searchPlanner(
        with query: PlannerSearchQuery?,
        ekEventStore: EKEventStore
    ) -> [String: [String]] {
        var datestamps: Set<String> = []

        var loadedPlanners: [String: Planner] = [:]

        // 1. Load all planners whose location matches searchText. Add the datestamps to the Set.

        // 1. Load all events that have a matching title or location.
        // 2. Load all datestamps that CAN hold that event. If both already exist in the Set, continue.
        // 3. Load the planner if it hasnt loaded, and check that the planner can hold the event.
        // 4. If yes, add the planner datestamp to the Set.

        // 5. Loop over the calendar events for the last 3 years and next 3 years. Assess them the same way as above.

        return [:]
    }

    // MARK: - Helper Functions

    private func createPlanner(for datestamp: String) -> Planner {
        let planner = Planner(datestamp: datestamp, location: nil)
        insert(planner)

        self.safeSave("planner.createPlanner")

        return planner
    }

}
