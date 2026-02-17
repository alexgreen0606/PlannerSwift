//
//  PlannerBuilder.swift
//  Planner
//
//  Created by Alex Green on 2/14/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerBuilderView: View {
    private let datestamp: String
    private let plannerSettings: PlannerSettings
    private let calendarSettings: CalendarSettings
    private let dismiss: () -> Void

    init(
        datestamp: String,
        plannerSettings: PlannerSettings,
        calendarSettings: CalendarSettings,
        dismiss: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.plannerSettings = plannerSettings
        self.calendarSettings = calendarSettings
        self.dismiss = dismiss

        _planners = Query(
            filter: #Predicate<Planner> { $0.datestamp == datestamp }
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
                PlannerView(
                    planner: planner,
                    plannerSettings: plannerSettings,
                    calendarSettings: calendarSettings,
                    dismiss: dismiss
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
