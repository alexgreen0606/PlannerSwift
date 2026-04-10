//
//  PlannerSearchTab.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import Fuse
import SwiftData
import SwiftDate
import SwiftUI
import SwiftUIIntrospect

// Clean

struct PlannerSearchTabView: View {
    private let todaystamp: String
    private let settings: PlannerSettings
    private let namespace: Namespace.ID

    init(
        todaystamp: String,
        settings: PlannerSettings,
        namespace: Namespace.ID
    ) {
        self.todaystamp = todaystamp
        self.settings = settings
        self.namespace = namespace

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == todaystamp
            }
        )
    }

    @Query private var planners: [Planner]

    private var todayDay: DateInRegion? {
        guard let todayPlanner = planners.first else {
            return nil
        }
        return todayPlanner.datestamp.startOfDay(
            in: todayPlanner.region(settings: settings)
        )
    }

    var body: some View {
        if let todayDay {
            PlannerSearchResultsView(
                todayDay: todayDay,
                settings: settings,
                namespace: namespace
            )
        }
    }
}
