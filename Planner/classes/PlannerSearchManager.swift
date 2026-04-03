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
    private var plannerSearchActor: PlannerSearchActor? = nil
    private var settings: PlannerSettings? = nil
    private var ekEventStore: EKEventStore? = nil

    @Published var results: [String: [String]] = [:]
    @Published var activeQuery: PlannerSearchQuery? = nil

    @Published var topDatestamp: String? = nil
    @Published var sortedUpcomingYears: [String] = []

    func initializeManager(
        modelContainer: ModelContainer,
        settings: PlannerSettings,
        ekEventStore: EKEventStore
    ) {
        self.plannerSearchActor = PlannerSearchActor(
            modelContainer: modelContainer
        )
        self.settings = settings
        self.ekEventStore = ekEventStore
    }

    func search(with query: PlannerSearchQuery) {
        guard let plannerSearchActor, let settings, let ekEventStore else {
            return
        }

        Task {
            let results = await plannerSearchActor.search(
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
