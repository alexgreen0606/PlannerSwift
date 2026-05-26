//
//  SearchRoot.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import Fuse
import SwiftData
import SwiftDate
import SwiftUI

struct SearchRootView: View {
    let todayDay: DateInRegion
    let settings: PlannerSettings
    let namespace: Namespace.ID

    init(
        todayDay: DateInRegion,
        settings: PlannerSettings,
        namespace: Namespace.ID
    ) {
        self.todayDay = todayDay
        self.settings = settings
        self.namespace = namespace

        _draftQuery = State(
            initialValue: PlannerSearchQuery(
                text: "",
                calendarIds: [],
                past: false,
                todayStartOfDay: todayDay,
                fuse: Fuse()
            )
        )
    }

    @Environment(\.isSearching) private var isSearching
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerSearchStore: PlannerSearchStore
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @State private var draftQuery: PlannerSearchQuery

    @State private var searchTask: Task<Void, Never>?

    private var noResultsLabel: String {
        guard let activeQuery = plannerSearchStore.results.activeQuery else {
            return ""
        }

        if activeQuery.isSearching {
            return
                "No matching events, trips, or locations in the \(activeQuery.timeFrameLabel)"
        }

        return "No \(activeQuery.timeFrameLabel) events, trips, or locations"
    }

    // MARK: - Body

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
                                    SearchResultPlannerPreviewView(
                                        datestamp: datestamp,
                                        activeQuery: plannerSearchStore
                                            .results.activeQuery,
                                        settings: settings,
                                        namespace: namespace
                                    )
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                YearSectionHeader(year)
                            }
                            .listSectionMargins(.top, 0)
                        }
                    }
                    .animateLazyAction(
                        from: todaystampService.todaystamp
                    )
                    .listStyle(.plain)
                    .refreshable {
                        weatherStore.beginFreshReload()
                        calendarStore.refreshCalendarsAndAccess()
                        locationService.loadDeviceLocation()
                        plannerSyncService.rebuildAllData()
                    }
                    .background(Color.appBackground)
                    .safeAreaInset(edge: .top) {
                        Color.clear.frame(
                            height: geo.safeAreaInsets.top
                                - geo.safeAreaInsets.bottom + 32
                        )
                    }
                    .ignoresSafeArea(edges: .top)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(
                            height: isSearching ? geo.safeAreaInsets.bottom : 0
                        )
                    }
                    .overlay {
                        noResultsLabelView
                    }
                    .toolbar {
                        SearchFilterToolbarView(
                            draftQuery: $draftQuery,
                            settings: settings
                        )
                    }

                    // MARK: Scroll to top whenever the search results change.

                    .withScrollTrigger(
                        scrollProxy: scrollProxy,
                        trigger: plannerSearchStore.results.datestampMap,
                        id: plannerSearchStore.results.topDatestamp,
                        disabled: plannerSearchStore.results.topDatestamp == nil
                    )
                }
            }
        }
        .searchable(
            text: $draftQuery.text,
            prompt: "Search planner.."
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)

        // MARK: Re-search when the planners re-sync.

        .onChange(of: plannerSyncService.rebuildTrigger) { _, _ in
            search()
        }

        // MARK: Re-search when today's date changes.

        .onChange(of: todaystampService.todaystamp) {
            _,
            _ in
            search()
        }

        // MARK: Schedule a search each time the draft query changes.

        .onChange(of: draftQuery) { _, _ in
            scheduleSearch()
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var noResultsLabelView: some View {
        if plannerSearchStore.results.sortedYears.isEmpty {
            EmptyLabel(noResultsLabel)
                .padding(.horizontal)
        }
    }

    // MARK: - Functions

    private func search() {
        modelContext.safeSave("SearchRootView.search")
        plannerSearchStore.search(
            with: draftQuery,
            modelContainer: modelContext.container,
            modelContext: modelContext,
            plannerSyncService: plannerSyncService,
            todaystamp: todaystampService.todaystamp,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore
        )
    }

    private func scheduleSearch() {
        searchTask?.cancel()

        searchTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(850))
                guard !Task.isCancelled else { return }

                search()
            } catch {}
        }
    }
}
