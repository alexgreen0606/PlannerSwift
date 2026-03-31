//
//  PlannerSearchTab.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import Fuse
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerSearchTabView: View {
    @Binding var searchText: String
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @Environment(\.isSearching) private var isSearching
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var filteredCalendarIds: Set<String> = []
    @State private var filterPast: Bool = false
    @State private var topDatestamp: String?

    @State private var toolbarHeight: CGFloat = 0
    @State private var topInsetHeight: CGFloat = 49

    @State private var plannerMapTask: Task<Void, Never>?
    @State private var plannerSearchQuery: PlannerSearchQuery? = nil

    // Year (YYYY) -> Datestamps (YYYY-MM-DD)
    @State private var plannerMap: [String: [String]] = [:]

    // Sorted keys from plannerMap.
    @State private var sortedUpcomingYears: [String] = []

    private var sortedCalendars: [EKCalendar] {
        calendarStore.sortedCalendars.filter {
            !settings.hiddenCalendarIds.contains(
                $0.calendarIdentifier
            )
        }
    }

    private var emptyResultsLabel: String {
        guard let plannerSearchQuery else {
            return ""
        }

        if plannerSearchQuery.isSearching {
            return "No matching results"
        }

        return plannerSearchQuery.filterPast
            ? "No past events or trips" : "No upcoming events or trips"
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollViewReader { scrollProxy in
                    List {
                        ForEach(sortedUpcomingYears, id: \.self) { year in
                            Section {
                                ForEach(
                                    plannerMap[year] ?? [],
                                    id: \.self
                                ) {
                                    datestamp in
                                    PlannerBuilderView(
                                        datestamp: datestamp,
                                        settings: settings,
                                        previewType: .search,
                                        plannerSearchQuery: plannerSearchQuery,
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
                        trigger: plannerMap,
                        id: topDatestamp,
                        disabled: topDatestamp == nil
                    )

                    // Calculate the layout for the manual safe areas once the UI settles.
                    .onAppear {
                        DispatchQueue.main.async {
                            toolbarHeight = geo.safeAreaInsets.bottom
                            topInsetHeight =
                                geo.safeAreaInsets.top - toolbarHeight + 32
                        }
                    }

                    // Build the planner map whenever the calendar store refreshes.
                    .externalData(
                        key: calendarStore.reloadTrigger,
                        ready: true,
                        load: {
                            buildPlannerMap(scrollProxy: scrollProxy)
                        }
                    )

                    // Re-build the planner map when today's date changes.
                    .onChange(of: todaystampWatcher.todaystamp) {
                        _,
                        _ in
                        buildPlannerMap(scrollProxy: scrollProxy)
                    }

                    // Schedule a build of the planner map when the search query changes.
                    .onChange(of: searchText) { _, _ in
                        schedulePlannerMapBuild(scrollProxy: scrollProxy)
                    }

                    // Schedule a build of the planner map when the filtered calendars change.
                    .onChange(of: filteredCalendarIds) { _, _ in
                        schedulePlannerMapBuild(scrollProxy: scrollProxy)
                    }

                    // Schedule a build of the planner map when the time range change.
                    .onChange(of: filterPast) { _, _ in
                        schedulePlannerMapBuild(scrollProxy: scrollProxy)
                    }
                }
                .animateAsynchronousAction(from: todaystampWatcher.todaystamp)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var calendarFilterToolbarMenu: some ToolbarContent {
        if calendarStore.calendarAccessDenied == false {
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
        if sortedUpcomingYears.isEmpty {
            EmptyLabelView(
                text: emptyResultsLabel
            )
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

    // MARK: - Datestamp Builders

    private func buildPlannerMap(scrollProxy: ScrollViewProxy) {
        let queryText = {
            let trimmed =
                searchText
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.count == 1 {
                return ""
            }

            return trimmed.lowercased()
        }()

        let todayPlanner = modelContext.loadPlanner(
            for: todaystampWatcher.todaystamp
        )
        guard
            let todayStartOfDay = todayPlanner.datestamp.startOfDay(
                in: todayPlanner.region(settings: settings)
            )
        else {
            assertionFailure(
                "ERROR PlannerSearchTab.buildPlannerMap: Could not build startOfDay for \(todayPlanner.datestamp)"
            )
            return
        }

        plannerSearchQuery = PlannerSearchQuery(
            text: queryText,
            filteredCalendarIds: filteredCalendarIds,
            filterPast: filterPast,
            todayStartOfDay: todayStartOfDay,
            fuse: Fuse()
        )
        plannerMap = modelContext.searchPlanner(
            with: plannerSearchQuery,
            ekEventStore: calendarStore.ekEventStore,
            settings: settings
        )
        sortedUpcomingYears = plannerMap.keys.sorted()

        // Scroll to the top of the results.
        if let firstYear = sortedUpcomingYears.first {
            topDatestamp = plannerMap[firstYear]?.first
        }
    }

    private func schedulePlannerMapBuild(scrollProxy: ScrollViewProxy) {
        plannerMapTask?.cancel()

        plannerMapTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(600))
                guard !Task.isCancelled else { return }

                buildPlannerMap(scrollProxy: scrollProxy)

            } catch {}
        }
    }

}
