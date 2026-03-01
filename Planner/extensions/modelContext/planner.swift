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

extension ModelContext {

    @MainActor
    func ensurePlanner(
        planners: [Planner],
        datestamp: String
    ) {
        if planners.first != nil {
            return
        }

        let planner = Planner(datestamp: datestamp, location: nil)
        insert(planner)

        do {
            try save()
        } catch {
            assertionFailure(
                "Failed to create Planner for \(datestamp): \(error)"
            )
        }
    }

    @MainActor
    func loadPlanner(
        for datestamp: String
    ) -> Planner {

        let descriptor = FetchDescriptor<Planner>(
            predicate: #Predicate<Planner> { planner in
                planner.datestamp == datestamp
            }
        )

        do {
            let planners = try fetch(descriptor)

            guard let planner = planners.first else {
                return Planner(datestamp: datestamp, location: nil)
            }

            return planner
        } catch {
            let newPlanner = Planner(datestamp: datestamp, location: nil)

            insert(newPlanner)

            do {
                try save()
            } catch {
                print("ERROR planner.loadPlanner: \(error)")
            }

            return newPlanner
        }
    }

    @MainActor
    func updateLocation(
        for planner: Planner,
        location: Location?,
        region: Region,
        settings: PlannerSettings,
        storageEvents: [PlannerEvent]
    ) {

        guard let newStartOfDay = planner.datestamp.startOfDay(in: region)
        else {
            assertionFailure(
                "ERROR planner.updateLocation: Could not create new startOfDay for \(planner.datestamp)"
            )
            return
        }

        planner.location = location

        // Update the date of all untimed events to ensure they appear in the new Planner window.
        for event in storageEvents {
            if !event.hasTime {
                event.date = newStartOfDay.date
            }
        }

        do {
            try save()
        } catch {
            assertionFailure(
                "ERROR planner.updateLocation: \(error)"
            )
        }
    }

    @MainActor
    func deleteOldPlanners(
        from planners: [Planner],
        before cutoffDate: Date
    ) {

        let cutoffDatestamp = cutoffDate.toFormat("yyyy-MM-dd")

        for planner in planners {
            if planner.datestamp < cutoffDatestamp {
                print("Deleting planner: \(planner.datestamp)")
                delete(planner)
            }
        }

        // Sepcial case: do NOT save the context here. This will be done in the parent
        // function that called this.
    }

    // TODO: deprecated for now.
    //    @MainActor
    //    private func loadAllPlannerEvents(
    //        for planner: Planner,
    //        startOfDay: DateInRegion,
    //        settings: PlannerSettings,
    //        loadCalendarEvents: (
    //            _ plannerKey: String,
    //            _ startOfDay: DateInRegion,
    //            _ hiddenCalendarIds: Set<String>
    //        ) -> PlannerCalendarData
    //    ) -> [PlannerEvent] {
    //        let plannerEvents = getEvents(for: startOfDay)
    //
    //        let calendarData = loadCalendarEvents(
    //            planner.key,
    //            startOfDay,
    //            settings.hiddenCalendarIds
    //        )
    //
    //        let calendarPlannerEvents = buildCalendarPlannerEvents(
    //            calendarEvents: calendarData.timedEvents,
    //            settings: settings
    //        )
    //
    //        return (plannerEvents + calendarPlannerEvents).sorted {
    //            $0.sortDate < $1.sortDate
    //        }
    //    }

}
