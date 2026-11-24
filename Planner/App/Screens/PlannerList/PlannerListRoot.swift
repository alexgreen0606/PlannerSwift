//
//  PlannerListRoot.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import SwiftData
import SwiftUI

struct PlannerListRootView: View {
    let settings: Settings
    let namespace: Namespace.ID

    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerService: PlannerService

    @State private var navigationPath = NavigationPath()

    @FocusState private var isSearchFocused: Bool

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

    /// Each time this changes, the list automatically scrolls to the given datestamp.
    private var autoScrollDatestampTrigger: String? {
        structuredDatestamps.sorted.first(where: {
            $0 >= todayService.todaystamp
        }) ?? structuredDatestamps.sorted.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            PlannerSearchWrapperView(
                isSearchFocused: $isSearchFocused,
                settings: settings
            ) {
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
                                    PlannerContextLoaderView_old(
                                        datestamp: datestamp,
                                        settings: settings
                                    ) {
                                        plannerContext in
                                        PlannerListPreviewView(
                                            planner: plannerContext.planner,
                                            sortedBirthdayEvents: plannerContext
                                                .eventContext
                                                .sortedBirthdayItems,
                                            sortedChipItems: plannerContext
                                                .eventContext
                                                .sortedChipItems,
                                            sortedPlannerEvents: plannerContext
                                                .eventContext
                                                .sortedPlannerEvents,
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
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("", systemImage: "gear") {
                                isSearchFocused = false
                                navigationPath.append(
                                    PlannerListPageId.settings
                                )
                            }
                        }
                    }

                    // MARK: Scroll to most relevant datestamp when results change.

                    .withScrollTrigger(
                        scrollProxy: scrollProxy,
                        trigger: structuredDatestamps.datestamps,
                        id: autoScrollDatestampTrigger,
                        disabled: structuredDatestamps.datestamps.isEmpty
                    )
                }
            }
            .navigationDestination(for: PlannerListPageId.self) {
                destination in
                switch destination {
                case .settings:
                    SettingsRootView(
                        settings: settings,
                        namespace: namespace
                    )
                }
            }
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
