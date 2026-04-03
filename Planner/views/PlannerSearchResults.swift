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

// Clean

struct PlannerSearchResultsView: View {
    let todayDay: DateInRegion
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @Environment(\.isSearching) private var isSearching
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var plannerSearchManager: PlannerSearchManager

    @State private var searchText: String = ""
    @State private var filteredCalendarIds: Set<String> = []
    @State private var filterPast: Bool = false

    @State private var toolbarHeight: CGFloat = 0
    @State private var topInsetHeight: CGFloat = 49

    @State private var plannerMapTask: Task<Void, Never>?

    private var sortedCalendars: [EKCalendar] {
        calendarStore.sortedCalendars.filter {
            !settings.hiddenCalendarIds.contains(
                $0.calendarIdentifier
            )
        }
    }

    private var emptyResultsLabel: String {
        guard let activeQuery = plannerSearchManager.activeQuery else {
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
                            plannerSearchManager.sortedUpcomingYears,
                            id: \.self
                        ) { year in
                            Section {
                                ForEach(
                                    plannerSearchManager.results[year] ?? [],
                                    id: \.self
                                ) {
                                    datestamp in
                                    PlannerBuilderView(
                                        datestamp: datestamp,
                                        settings: settings,
                                        previewType: .search,
                                        plannerSearchQuery: plannerSearchManager
                                            .activeQuery,
                                        header: {
                                            PlannerHeaderView(
                                                day: $0,
                                                title:
                                                    $0.proximityFormat(
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
                                                        ]
                                                    )
                                            )
                                        },
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
                        calendarFilterToolbarMenu
                    }
                    .refreshable {
                        weatherStore.beginFreshReload()
                        calendarStore.attemptFreshLoad(
                            hiddenCalendarIds: settings
                                .hiddenCalendarIds
                        )
                        deviceLocationManager.loadDeviceLocation()
                    }

                    // Scroll to top whenever the planner list changes.
                    .withScrollTrigger(
                        scrollProxy: scrollProxy,
                        trigger: plannerSearchManager.results,
                        id: plannerSearchManager.topDatestamp,
                        disabled: plannerSearchManager.topDatestamp == nil
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
                .animateAsynchronousAction(from: todaystampWatcher.todaystamp)
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search planner...",
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)

        // Re-buiuld the planner map when the calendar data changes.
        .onChange(of: calendarStore.reloadTrigger) { _, _ in
            searchPlanner()
        }

        // Re-build the planner map when today's date changes.
        .onChange(of: todaystampWatcher.todaystamp) {
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

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var calendarFilterToolbarMenu: some ToolbarContent {
        if calendarStore.accessDenied == false {
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Section("Timeframe") {
                        Toggle(
                            "Upcoming",
                            isOn: Binding(
                                get: {
                                    !filterPast
                                },
                                set: { isOn in
                                    filterPast.toggle()
                                }
                            )
                        )
                        Toggle(
                            "Past",
                            isOn: $filterPast
                        )
                    }

                    Section("Calendars") {
                        ForEach(sortedCalendars, id: \.calendarIdentifier) {
                            calendar in
                            Toggle(
                                isOn: Binding(
                                    get: {
                                        filteredCalendarIds.contains(
                                            calendar.calendarIdentifier
                                        )
                                    },
                                    set: { isOn in
                                        if isOn {
                                            filteredCalendarIds.insert(
                                                calendar.calendarIdentifier
                                            )
                                        } else {
                                            filteredCalendarIds.remove(
                                                calendar.calendarIdentifier
                                            )
                                        }
                                    }
                                )
                            ) {
                                HStack {
                                    Image(
                                        systemName: calendar.systemImageName(
                                            settings: settings
                                        )
                                    )
                                    .tint(calendar.color)

                                    Text(calendar.title)
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var emptyPlannersLabel: some View {
        if plannerSearchManager.sortedUpcomingYears.isEmpty {
            EmptyLabelView(emptyResultsLabel)
                .frame(height: ListLayout.EMPTY_LABEL_HEIGHT)
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
        let queryText = {
            let trimmed =
                searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.count == 1 {
                return ""
            }

            return trimmed.lowercased()
        }()

        plannerSearchManager.search(
            with: PlannerSearchQuery(
                text: queryText,
                filteredCalendarIds: filteredCalendarIds,
                filterPast: filterPast,
                todayStartOfDay: todayDay,
                fuse: Fuse()
            )
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
