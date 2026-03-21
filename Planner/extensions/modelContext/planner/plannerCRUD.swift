//
//  plannerCRUD.swift
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
                "ERROR plannerCRUD.updateLocation: Could not create new startOfDay for \(planner.datestamp)"
            )
            return
        }

        planner.location = newLocation

        // Set all untimed events' dates to the start of day in the planner's new location.
        for event in storageEvents where !event.hasTime {
            event.date = newStartOfDay.date
        }

        self.safeSave("plannerCRUD.updatePlannerLocation")
    }

    // MARK: - Helper Functions

    private func createPlanner(for datestamp: String) -> Planner {
        let planner = Planner(datestamp: datestamp, location: nil)
        insert(planner)

        self.safeSave("plannerCRUD.createPlanner")

        return planner
    }

}
