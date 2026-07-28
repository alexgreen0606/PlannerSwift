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
    let settings: Settings
    let namespace: Namespace.ID

    init(
        todayPlanner: Planner,
        settings: Settings,
        namespace: Namespace.ID
    ) {
        self.settings = settings
        self.namespace = namespace

        _draftQuery = State(
            initialValue: SearchQuery(
                text: "",
                calendarIds: [],
                past: false,
                todayStartOfDay: todayPlanner.startOfDay(settings: settings),
                fuse: Fuse()
            )
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerService: PlannerService

    @State private var draftQuery: SearchQuery

    @State private var searchTask: Task<Void, Never>?

    private var noResultsLabel: LocalizedStringKey {
        let activeQuery = plannerService.searchResults.activeQuery

        if activeQuery.isFiltering {
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
                            plannerService.searchResults.sortedYears
                                .enumerated(),
                            id: \.element
                        ) { index, year in
                            Section {
                                ForEach(
                                    plannerService.searchResults.datestampMap[
                                        year
                                    ] ?? [],
                                    id: \.self
                                ) {
                                    datestamp in
                                    PlannerContextLoaderView(
                                        datestamp: datestamp,
                                        settings: settings
                                    ) {
                                        context in
                                        SearchResultPlannerPreviewView(
                                            activeQuery: plannerService
                                                .searchResults.activeQuery,
                                            planner: context.planner,
                                            sortedPlannerEvents: context
                                                .eventContext
                                                .sortedPlannerEvents,
                                            sortedEventChips: context
                                                .eventContext.sortedEventChips,
                                            sortedBirthdayChips: context
                                                .eventContext
                                                .sortedBirthdayChips,
                                            settings: settings,
                                            namespace: namespace
                                        )
                                    }
                                    .listRowBackground(Color.clear)
                                }
                            } header: {
                                YearSectionHeader(year)
                            }
                            .listSectionMargins(.top, index == 0 ? 0 : 32)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        calendarService.loadCalendars()
                        locationService.loadDeviceLocation()
                        plannerService.refresh()
                        plannerService.search()
                    }
                    .background(Color.appBackground)
                    .safeAreaInset(edge: .top) {
                        SearchInsetView(
                            focused: Layout.TOOLBAR_HEIGHT,
                            blurred: geo.safeAreaInsets.top
                                - geo.safeAreaInsets.bottom + 32
                        )
                    }
                    .ignoresSafeArea(edges: .top)
                    .safeAreaInset(edge: .bottom) {
                        SearchInsetView(
                            focused: Layout.TOOLBAR_HEIGHT,
                            blurred: 0
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
                        trigger: plannerService.searchResults.datestampMap,
                        id: plannerService.searchResults.topDatestamp,
                        disabled: plannerService.searchResults.topDatestamp
                            == nil
                    )
                }
            }
        }
        .searchable(
            text: $draftQuery.text,
            prompt: "Search planner.."
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)

        // MARK: Schedule a search each time the draft query changes.

        .onChange(of: draftQuery) { _, _ in
            scheduleSearch()
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var noResultsLabelView: some View {
        if plannerService.searchResults.sortedYears.isEmpty
            && plannerService.didInitializeSearch
        {
            EmptyLabel(noResultsLabel)
                .padding(.horizontal, 64)
        }
    }

    // MARK: - Functions

    private func search() {
        plannerService.search(with: draftQuery)
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
