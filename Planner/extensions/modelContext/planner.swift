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

    // MARK: - ENSURE

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

    // MARK: - CREATE

    private func createPlanner(for datestamp: String) -> Planner {
        let planner = Planner(datestamp: datestamp, location: nil)

        insert(planner)
        self.safeSave("planner.createPlanner")

        return planner
    }

    // MARK: - READ

    @MainActor
    func getPlanner(
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

    @MainActor
    func getEarliestPlannerDay(
        for date: Date,
        settings: PlannerSettings,
        requireExactMatch: Bool = false
    ) -> DateInRegion? {

        let sortedPossibleDatestamps =
            getSortedPossibleDatestamps(for: date)

        for datestamp in sortedPossibleDatestamps {

            let planner = self.getPlanner(for: datestamp)
            guard
                let plannerDay = planner.datestamp.startOfDay(
                    in: planner.region(settings: settings)
                )
            else {
                continue
            }

            if requireExactMatch {
                if date == plannerDay.date {
                    return plannerDay
                }
            } else if date.belongsTo(plannerDay) {
                return plannerDay
            }
        }

        // Date does not belong to any planner.
        return nil
    }

    @MainActor
    func getUpperSortDate(for plannerDay: DateInRegion) -> Date {
        let storageEvents = self.getSortedStorageEvents(for: plannerDay)
        return generateSortDate(
            at: 0,
            in: storageEvents,
            plannerDay: plannerDay
        )
    }

    // MARK: - UPDATE

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
            return
        }

        planner.location = newLocation

        for event in storageEvents where !event.hasTime {
            // Untimed events MUST have their date set to the planner's startOfDay.
            event.date = newStartOfDay.date
        }

        self.safeSave("planner.updatePlannerLocation")
    }

    @MainActor
    func togglePlannerRoutineExclusion(
        for planner: Planner,
        plannerEvents: [PlannerEvent]
    ) {
        planner.deletedRoutineEventIds.removeAll()

        if planner.finalExcludeRoutine {
            planner.excludeRoutine = false
        } else {
            planner.excludeRoutine = true
            
            // Delete all routine event records.
            for plannerEvent in plannerEvents {
                if plannerEvent.routineEvent != nil {
                    self.delete(plannerEvent)
                }
            }
        }

        if let trip = planner.trip,
            trip.excludeRoutines == planner.excludeRoutine
        {
            // Revert flag back to nil so it inherits from the trip.
            planner.excludeRoutine = nil
        }

        self.safeSave("planner.togglePlannerRoutineExclusion")
    }

}
