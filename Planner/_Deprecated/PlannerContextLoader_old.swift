//
//  PlannerContextLoader.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

import SwiftUI

struct PlannerContextLoaderView_old<Content: View>: View {
    let datestamp: String
    let settings: Settings
    let content: (PlannerContext_old) -> Content

    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    // MARK: - Body

    var body: some View {
        PlannerLoaderView(datestamp: datestamp) { planner in
            PlannerEventContextLoaderView_old(
                planner: planner,
                plannerService: plannerService,
                settings: settings
            ) { eventContext in
                content(
                    PlannerContext_old(
                        planner: planner,
                        eventContext: eventContext
                    )
                )
            }
        }
    }
}
