//
//  PlannerList.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import SwiftData
import SwiftUI

/// The list view of the Planner tab: upcoming planners (or search results), grouped by year.
struct PlannerListView: View {
    let settings: Settings
    let namespace: Namespace.ID

    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerService: PlannerService

    private var plannerListContext: PlannerListContext {
        plannerService.plannerListContext
    }

    private var structuredDatestamps: StructuredDatestampsContext {
        plannerListContext.structuredDatestamps
    }

    private var noResultsLabel: LocalizedStringKey {
        guard plannerService.activeQuery != nil else {
            return "No upcoming plans"
        }

        return
            "No matching events, trips, or locations"
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(
                    structuredDatestamps.sortedYears
                        .enumerated(),
                    id: \.element
                ) { yearIndex, year in
                    Section {
                        ForEach(
                            structuredDatestamps.sortedByYear[
                                year
                            ]!,
                            id: \.self
                        ) {
                            datestamp in
                            PlannerPreviewLoaderView(
                                datestamp: datestamp,
                                activeQuery: plannerService.activeQuery,
                                settings: settings
                            ) { planner, previewContext in
                                PlannerListPreviewView(
                                    planner: planner,
                                    context: previewContext,
                                    settings: settings,
                                    namespace: namespace
                                )
                            }
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        if year != todayService.todaystamp.year
                            || plannerListContext.query?.isDefault
                                == false
                        {
                            YearSectionHeader(year)
                        }
                    }
                    .listSectionMargins(.top, yearIndex == 0 ? 0 : 32)
                    .listSectionSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                calendarService.loadCalendars()
                locationService.loadDeviceLocation()
                plannerService.refresh()
                plannerService.loadPlannerList()
            }
            .background(Color.appBackground.ignoresSafeArea())
            .overlay {
                noResultsLabelView
            }

            // MARK: Scroll to top when results change.

            .withScrollTrigger(
                scrollProxy: scrollProxy,
                trigger: structuredDatestamps.datestamps,
                id: structuredDatestamps.datestamps.first,
                disabled: structuredDatestamps.datestamps.isEmpty
            )
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var noResultsLabelView: some View {
        if structuredDatestamps.datestamps.isEmpty {
            ContentUnavailableView(
                "No Results",
                systemImage: "magnifyingglass",
                description: Text(noResultsLabel)
            )
        }
    }
}
