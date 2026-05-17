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
            plannerContext,
            eventContext in
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
                            planner: plannerContext.planner,
                            plannerDay: plannerContext.plannerDay,
                            plannerLocation: plannerContext.plannerLocation,
                            settings: settings
                        )
                    }
                }

                PlannerPreviewView(
                    type: .search,
                    searchQuery: plannerSearchQuery,
                    planner: plannerContext.planner,
                    plannerDay: plannerContext.plannerDay,
                    plannerLocation: plannerContext.plannerLocation,
                    plannerEvents: eventContext.sortedPlannerEvents,
                    calendarDayData: eventContext.calendarDayData,
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
