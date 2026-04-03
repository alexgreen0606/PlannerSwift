//
//  PlannerSearchManager.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import Combine
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

@MainActor
final class PlannerSearchManager: ObservableObject {
    private var plannerSearchActor: PlannerSearchActor?

    @Published var results: [String: [String]] = [:]
    @Published var activeQuery: PlannerSearchQuery? = nil

    @Published var topDatestamp: String? = nil
    @Published var sortedUpcomingYears: [String] = []

    func search(
        with query: PlannerSearchQuery,
        modelContainer: ModelContainer,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) {

        plannerSearchActor =
            plannerSearchActor
            ?? PlannerSearchActor(
                modelContainer: modelContainer
            )

        Task {
            let results = await plannerSearchActor!.search(
                query: query,
                ekEventStore: ekEventStore,
                settings: settings
            )

            guard !Task.isCancelled else { return }

            self.results = results
            self.activeQuery = query
            self.sortedUpcomingYears = results.keys.sorted {
                query.filterPast ? $0 > $1 : $0 < $1
            }
            if let firstYear = sortedUpcomingYears.first {
                self.topDatestamp = results[firstYear]?.first
            }
        }
    }

}
