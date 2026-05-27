//
//  SearchResultPlannerPreview.swift
//  Planner
//
//  Created by Alex Green on 5/13/26.
//

import SwiftData
import SwiftUI

struct SearchResultPlannerPreviewView: View {
    let datestamp: String
    let activeQuery: PlannerSearchQuery?
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    // MARK: - Body

    var body: some View {
        PlannerContextLoaderView(datestamp: datestamp, settings: settings) { context in
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    PlannerHeaderView(
                        datestamp: datestamp,
                        title:
                        datestamp.proximityFormat(
                            using: [
                                ProximityRule(
                                    proximity:
                                    .next7Days,
                                    format: .weekday
                                ),
                                ProximityRule(
                                    proximity:
                                    .fallback,
                                    // Note: Never show the year. Shown in section header.
                                    format:
                                    .dateWithoutYear
                                ),
                            ],
                            todaystamp:
                            todayService
                                .todaystamp
                        )
                    )

                    Spacer()

                    if let activeQuery {
                        SearchResultWeatherView(
                            activeQuery: activeQuery,
                            planner: context.planner,
                            settings: settings
                        )
                    }
                }
                .frame(maxWidth: .infinity)

                PlannerPreviewView(
                    type: .search,
                    searchQuery: activeQuery,
                    planner: context.planner,
                    plannerEvents: context.eventContext.sortedPlannerEvents,
                    calendarDayData: context.eventContext.calendarDayData,
                    settings: settings
                )
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
