//
//  PlannerSearchResults.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import EventKit
import Fuse
import SwiftData
import SwiftDate
import SwiftUI
import SwiftUIIntrospect

struct PlannerSearchResultsView: View {
    let todayDay: DateInRegion
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @Environment(\.isSearching) private var isSearching
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var TodaystampService: TodaystampService
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var LocationService: LocationService
    @EnvironmentObject private var plannerSearchStore: PlannerSearchStore
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncStore

    @State private var searchText: String = ""
    @State private var filteredCalendarIds: Set<String> = []
    @State private var filterPast: Bool = false

    @State private var toolbarHeight: CGFloat = 0
    @State private var topInsetHeight: CGFloat = 49

    @State private var plannerMapTask: Task<Void, Never>?

    private var emptyResultsLabel: String {
        guard let activeQuery = plannerSearchStore.results.activeQuery else {
            return ""
        }

        if activeQuery.isSearching {
            return "No matching results"
        }

        return activeQuery.filterPast
            ? "No past events or trips" : "No upcoming events or trips"
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollViewReader { scrollProxy in
                    List {
                        ForEach(
                            plannerSearchStore.results.sortedYears,
                            id: \.self
                        ) { year in
                            Section {
                                ForEach(
                                    plannerSearchStore.results.datestampMap[
                                        year
                                    ] ?? [],
                                    id: \.self
                                ) {
                                    datestamp in
                                    PlannerSearchResultView(
                                        datestamp: datestamp,
                                        settings: settings,
                                        plannerSearchQuery: plannerSearchStore.results.activeQuery,
                                        namespace: namespace
                                    )
                                    .listRowBackground(Color.clear)
                                    .id(datestamp)
                                }
                            } header: {
                                YearSectionHeaderView(year)
                            }
                            .listSectionMargins(.top, 0)
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.appBackground)
                    .overlay {
                        emptyPlannersLabel
                    }
                    .safeAreaInset(edge: .top) {
                        topSpacer
                    }
                    .ignoresSafeArea(edges: .top)
                    .safeAreaInset(edge: .bottom) {
                        bottomSpacer
                    }
                    .toolbar {
                        PlannerSearchToolbar(
                            filterPast: $filterPast,
                            filteredCalendarIds: $filteredCalendarIds,
                            settings: settings
                        )
                    }
                    .refreshable {
                        weatherStore.beginFreshReload()
                        calendarStore.refreshCalendarsAndAccess()
                        LocationService.loadDeviceLocation()
                        PlannerSyncStore.rebuildAllData()
                    }

                    // Scroll to top whenever the planner list changes.
                    .withScrollTrigger(
                        scrollProxy: scrollProxy,
                        trigger: plannerSearchStore.results.datestampMap,
                        id: plannerSearchStore.results.topDatestamp,
                        disabled: plannerSearchStore.results.topDatestamp == nil
                    )

                    // Calculate the layout for the manual safe areas once the UI settles.
                    .onAppear {
                        DispatchQueue.main.async {
                            toolbarHeight = geo.safeAreaInsets.bottom
                            topInsetHeight =
                                geo.safeAreaInsets.top - toolbarHeight + 32
                        }
                    }
                }
                .animateAsynchronousAction(from: TodaystampService.todaystamp)

            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search planner...",
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)

        // Re-build the planner map when the calendar data changes.
        .onChange(of: PlannerSyncStore.rebuildTrigger) { _, _ in
            searchPlanner()
        }

        // Re-build the planner map when today's date changes.
        .onChange(of: TodaystampService.todaystamp) {
            _,
            _ in
            searchPlanner()
        }

        // Schedule a build of the planner map when the search query changes.
        .onChange(of: searchText) { _, _ in
            schedulePlannerSearch()
        }

        // Schedule a build of the planner map when the filtered calendars change.
        .onChange(of: filteredCalendarIds) { _, _ in
            schedulePlannerSearch()
        }

        // Schedule a build of the planner map when the time range change.
        .onChange(of: filterPast) { _, _ in
            schedulePlannerSearch()
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var emptyPlannersLabel: some View {
        if plannerSearchStore.results.sortedYears.isEmpty {
            EmptyLabelView(emptyResultsLabel)
        }
    }

    private var topSpacer: some View {
        Color.clear
            .frame(
                height: topInsetHeight
            )
    }

    private var bottomSpacer: some View {
        Color.clear.frame(
            height: isSearching ? toolbarHeight : 0
        )
    }

    // MARK: - Functions

    private func searchPlanner() {
        modelContext.safeSave("PlannerSearchResults.searchPlanner")
        plannerSearchStore.search(
            with: PlannerSearchQuery(
                text: searchText.querySanitized,
                filteredCalendarIds: filteredCalendarIds,
                filterPast: filterPast,
                todayStartOfDay: todayDay,
                fuse: Fuse()
            ),
            modelContainer: modelContext.container,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore
        )
    }

    private func schedulePlannerSearch() {
        plannerMapTask?.cancel()

        plannerMapTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }

                searchPlanner()

            } catch {}
        }
    }

}
