//
//  PlannerSearchToolbar.swift
//  Planner
//
//  Created by Alex Green on 11/27/26.
//

import SwiftUI

struct PlannerSearchToolbarContent: ToolbarContent {
    var isSearchFocused: FocusState<Bool>.Binding
    let settings: Settings

    @EnvironmentObject private var plannerService: PlannerService

    private var activeQuery: PlannerSearchQuery? {
        plannerService.activeQuery
    }

    // MARK: - Body

    var body: some ToolbarContent {
        PlannerFilterToolbarView(
            draftQuery: $plannerService.draftQuery,
            filterCount: activeQuery?.filterCount,
            settings: settings
        )

        ToolbarItem(placement: .topBarLeading) {
            Button("", systemImage: "magnifyingglass") {
                isSearchFocused.wrappedValue.toggle()
            }
            .badge(
                activeQuery?.isSearchingText == true ? "1" : nil
            )
        }
        
        ToolbarSpacer(.fixed, placement: .topBarLeading)

        if activeQuery?.filterCount != nil
            || activeQuery?.isSearchingText == true
        {
            ToolbarItem(placement: .topBarLeading) {
                Button("Reset") {
                    plannerService.draftQuery = PlannerSearchQuery(
                        text: "",
                        calendarIds: []
                    )

                    withAnimation {
                        plannerService.loadPlannerList()
                    }
                }
            }
        }
    }
}
