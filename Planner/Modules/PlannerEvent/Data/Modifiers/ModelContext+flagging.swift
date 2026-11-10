//
//  ModelContext+flagging.swift
//  Planner
//
//  Created by Alex Green on 11/9/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    @MainActor
    func carryOverPastFlaggedPlannerEvents(
        todaystamp: String,
        settings: Settings
    ) {
        let todayPlanner = getPlanner(for: todaystamp)
        let todayStartOfDay = todayPlanner.startOfDay(settings: settings)
        let reverseSortedEvents = getReverseSortedCarryOverEvents(
            todayStartOfDay: todayStartOfDay
        )

        var sortedListEvents = getSortedListEvents(on: todayStartOfDay)

        for plannerEvent in reverseSortedEvents {
            plannerEvent.time = nil
            plannerEvent.datestamp = todaystamp
            plannerEvent.sortDate = generatePlannerEventSortDate(
                at: 0,
                in: sortedListEvents,
                startOfDay: todayStartOfDay
            )

            // Track the event at its new position in the planner.
            sortedListEvents.insert(plannerEvent, at: 0)
        }

        safeSave("ModelContext+flagging carryOverPastFlaggedPlannerEvents")
    }

    // MARK: - READ

    func getReverseSortedCarryOverEvents(todayStartOfDay: DateInRegion)
        -> [PlannerEvent]
    {
        do {
            return try fetch(
                FetchDescriptor<PlannerEvent>(
                    predicate: PlannerEvent.carryOverEvents(
                        todayStartOfDay: todayStartOfDay
                    ),
                    sortBy: [
                        SortDescriptor(\PlannerEvent.sortDate, order: .reverse)
                    ],
                )
            )
        } catch {
            assertionFailure(
                "ERROR ModelContext+flagging getReverseSortedCarryOverEvents: \(error)"
            )
        }

        return []
    }
}
