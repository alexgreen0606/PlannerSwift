//
//  ModelContext+Calendar.swift
//  Planner
//
//  Created by Alex Green on 11/19/26.
//

import SwiftData

extension ModelContext {
    func getStructuredPlannerPreviewContexts(
        for datestamps: [String],
        activeQuery: PlannerSearchQuery?,
        settings: Settings
    ) -> [String: StructuredPlannerPreviewContext] {
        var contexts: [String: StructuredPlannerPreviewContext] = [:]

        guard !datestamps.isEmpty else {
            return contexts
        }

        let planners = getBulkPlanners(for: Set(datestamps))

        for planner in planners {
            let startOfDay = planner.startOfDay(settings: settings)

            let sortedPlannerEvents = getSortedListEvents(on: startOfDay)
                .filterOutRoutineUnlessSearching(
                    activeQuery: activeQuery
                )

            contexts[planner.datestamp] = StructuredPlannerPreviewContext(
                planner: planner,
                activeQuery: activeQuery,
                sortedBirthdayEvents: getSortedBirthdayEvents(on: startOfDay),
                sortedEventChips: getSortedEventChips(on: startOfDay),
                sortedPlannerEvents: sortedPlannerEvents,
                maxPreviewSlots: 4
            )
        }

        return contexts
    }
}
