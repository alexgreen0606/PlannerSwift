//
//  PlannerCardVerticalBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/15/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerCardVerticalBuilderView: View {
    private let datestamp: String
    private let plannerSettings: PlannerSettings
    private let calendarSettings: CalendarSettings
    @Binding private var openPlanner: Planner?

    init(
        datestamp: String,
        plannerSettings: PlannerSettings,
        calendarSettings: CalendarSettings,
        openPlanner: Binding<Planner?>
    ) {
        self.datestamp = datestamp
        self.plannerSettings = plannerSettings
        self.calendarSettings = calendarSettings
        self._openPlanner = openPlanner

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    @Environment(\.modelContext) private var modelContext

    @Query private var planners: [Planner]

    private var planner: Planner? {
        planners.first
    }

    var body: some View {
        Group {
            if let planner {
                PlannerCardVerticalView(
                    planner: planner,
                    plannerSettings: plannerSettings,
                    calendarSettings: calendarSettings,
                    openPlanner: $openPlanner
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
