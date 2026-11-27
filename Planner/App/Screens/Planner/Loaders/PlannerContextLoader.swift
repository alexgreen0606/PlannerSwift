//
//  PlannerContextLoader.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import SwiftUI

struct PlannerContext {
    let planner: Planner
    let itemContext: PlannerItemContext
}

struct PlannerContextLoaderView<Content: View>: View {
    let datestamp: String
    let settings: Settings
    let content: (PlannerContext) -> Content

    @EnvironmentObject private var calendarService: CalendarService

    // MARK: - Body

    var body: some View {
        PlannerLoaderView(datestamp: datestamp) { planner in
            PlannerItemContextLoaderView(
                planner: planner,
                calendarService: calendarService,
                settings: settings
            ) { itemContext in
                content(
                    PlannerContext(
                        planner: planner,
                        itemContext: itemContext
                    )
                )
            }
        }
    }
}
