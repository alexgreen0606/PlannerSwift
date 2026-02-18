//
//  PlannerCardVerticalBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/15/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerPreviewBuilderView: View {
    private let datestamp: String
    private let type: PlannerPreviewType
    private let plannerSettings: PlannerSettings
    @Binding private var openPlanner: Planner?

    init(
        datestamp: String,
        type: PlannerPreviewType,
        plannerSettings: PlannerSettings,
        openPlanner: Binding<Planner?>
    ) {
        self.datestamp = datestamp
        self.type = type
        self.plannerSettings = plannerSettings
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
        ZStack {
            if let planner {
                PlannerPreviewView(
                    planner: planner,
                    type: type,
                    plannerSettings: plannerSettings,
                    openPlanner: $openPlanner
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
