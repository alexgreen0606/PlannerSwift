//
//  PlannerSearchResult.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct PlannerSearchResultView: View {
    let datestamp: String
    let settings: PlannerSettings
    let plannerSearchQuery: PlannerSearchQuery?
    let namespace: Namespace.ID

    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    var body: some View {
        PlannerLoaderView(datestamp: datestamp, settings: settings) {
            context in
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    PlannerHeaderView(
                        datestamp: datestamp,
                        title:
                        datestamp.proximityFormat(
                            using: [
                                ProximityRule(
                                    proximity:
                                    .withinADay,
                                    format:
                                    .countdown
                                ),
                                ProximityRule(
                                    proximity:
                                    .next7Days,
                                    format: .weekday
                                ),
                                ProximityRule(
                                    proximity:
                                    .fallback,
                                    // Custom Here: Never show the year.
                                    format:
                                    .dateWithoutYear
                                ),
                            ],
                            todaystamp:
                            todaystampService
                                .todaystamp
                        )
                    )

                    Spacer()

                    if let plannerSearchQuery {
                        SearchResultsWeatherView(
                            plannerSearchQuery: plannerSearchQuery,
                            planner: context.planner,
                            plannerDay: context.plannerDay,
                            plannerLocation: context.plannerLocation,
                            settings: settings
                        )
                    }
                }

                if let calendarDayData = context.calendarDayData {
                    PlannerPreviewView(
                        type: .search,
                        searchQuery: plannerSearchQuery,
                        header: EmptyView(), // TODO: remove header here
                        planner: context.planner,
                        plannerDay: context.plannerDay,
                        plannerLocation: context.plannerLocation,
                        plannerEvents: context.sortedPlannerEvents,
                        calendarDayData: calendarDayData,
                        settings: settings
                    )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .matchedTransitionSource(
            id: datestamp,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture {
            plannerCoverStore.context = PlannerCoverContext(
                datestamp: datestamp
            )
        }
    }
}
