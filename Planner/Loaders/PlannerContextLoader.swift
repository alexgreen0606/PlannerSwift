//
//  PlannerContextLoader.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

import SwiftUI

struct PlannerContextLoaderView<Content: View>: View {
    let datestamp: String
    let settings: Settings
    let content: (PlannerContext) -> Content

    @EnvironmentObject private var plannerService: PlannerService

    // MARK: - Body

    var body: some View {
        PlannerLoaderView(datestamp: datestamp) { planner in
            PlannerEventContextLoaderView(
                planner: planner,
                plannerService: plannerService,
                settings: settings
            ) { eventContext in
                content(
                    PlannerContext(
                        planner: planner,
                        eventContext: eventContext
                    )
                )
            }
        }
    }
}
