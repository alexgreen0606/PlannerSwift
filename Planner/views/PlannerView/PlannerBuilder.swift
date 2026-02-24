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
    private let settings: PlannerSettings
    private let dismiss: () -> Void

    init(
        datestamp: String,
        settings: PlannerSettings,
        dismiss: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.settings = settings
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
                    settings: settings,
                    dismiss: dismiss
                )
            }
        }
        .task {
            modelContext.ensurePlanner(planners: planners, datestamp: datestamp)
        }
    }
}
