//
//  PlannerSearchStore.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import Combine
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerSearchResults {
    let datestampMap: [String: [String]]
    let topDatestamp: String?
    let sortedYears: [String]
    let activeQuery: PlannerSearchQuery?

    init(
        datestampMap: [String: [String]] = [:],
        topDatestamp: String? = nil,
        sortedYears: [String] = [],
        activeQuery: PlannerSearchQuery? = nil
    ) {
        self.datestampMap = datestampMap
        self.topDatestamp = topDatestamp
        self.sortedYears = sortedYears
        self.activeQuery = activeQuery
    }
}

@MainActor
final class PlannerSearchStore: ObservableObject {
    private var plannerSearchService: PlannerSearchService?

    @Published var results = PlannerSearchResults()

    func search(
        with query: PlannerSearchQuery,
        modelContainer: ModelContainer,
        modelContext: ModelContext,
        plannerSyncService: PlannerSyncService,
        todaystamp: String,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) {
        plannerSearchService =
            plannerSearchService
                ?? PlannerSearchService(
                    modelContainer: modelContainer
                )

        Task {
            let datestampMap = await plannerSearchService!.search(
                query: query,
                ekEventStore: ekEventStore,
                settings: settings
            )

            guard !Task.isCancelled else { return }

            let fullPlannerContexts = modelContext.getBulkPlannerContexts(
                for: Set(datestampMap.values.flatMap { $0 }),
                settings: settings
            )

            // MARK: Eager-build all results before displaying them in the UI.

            for context in fullPlannerContexts {
                let _ = plannerSyncService.syncPlanner(
                    context.planner,
                    plannerDay: context.plannerDay,
                    sortedPlannerEvents: context.sortedPlannerEvents,
                    todaystamp: todaystamp,
                    ekEventStore: ekEventStore,
                    modelContext: modelContext,
                    settings: settings
                )
            }

            // MARK: Return results so the UI can display them.

            await MainActor.run {
                let sortedKeys = datestampMap.keys.sorted {
                    query.past ? $0 > $1 : $0 < $1
                }

                let top = sortedKeys.first.flatMap { datestampMap[$0]?.first }

                self.results = PlannerSearchResults(
                    datestampMap: datestampMap,
                    topDatestamp: top,
                    sortedYears: sortedKeys,
                    activeQuery: query
                )
            }
        }
    }
}
