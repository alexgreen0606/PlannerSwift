//
//  PlannerSearchTab.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct PlannerSearchTabView: View {
    @Binding var searchText: String
    let settings: PlannerSettings
    let namespace: Namespace.ID

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.isSearching) private var isSearching
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var weatherStore: WeatherStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var filteredCalendarIds: Set<String> = []
    @State private var scrollToSoonestDatestampTrigger: UUID = UUID()

    @State private var toolbarHeight: CGFloat = 0
    @State private var topInsetHeight: CGFloat = 49

    // Year (YYYY) -> Datestamps (YYYY-MM-DD)
    @State private var plannerMap: [String: [String]] = [:]
    @State private var plannerMapTask: Task<Void, Never>?

    // Sorted keys from plannerMap.
    @State private var sortedUpcomingYears: [String] = ["2026"]

    private var sortedCalendars: [EKCalendar] {
        calendarStore.sortedCalendars.filter {
            !settings.hiddenCalendarIds.contains(
                $0.calendarIdentifier
            )
        }
    }

    // TODO: this should store the datestamp closest to today
    private var topDatestamp: String? {
        guard let firstYear = sortedUpcomingYears.first else {
            return nil
        }

        return plannerMap[firstYear]?.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollViewReader { scrollProxy in
                    List {
                        ForEach(sortedUpcomingYears, id: \.self) { year in
                            Section {
                                ForEach(
                                    plannerMap[year] ?? [
                                        "2026-03-06", "2026-03-07",
                                        "2026-03-08", "2026-03-09",
                                        "2026-03-10",
                                    ],
                                    id: \.self
                                ) {
                                    datestamp in
                                    PlannerBuilderView(
                                        datestamp: datestamp,
                                        settings: settings,
                                        previewType: .search,
                                        namespace: namespace
                                    )
                                    .listRowBackground(Color.clear)
                                    .id(datestamp)
                                }
                            } header: {
                                upcomingYearHeader(year)
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

                    // Keep the list scrolled to the top whenever the results change.
                    // TODO: scroll to the date >= today
                    .withScrollTrigger(
                        scrollProxy: scrollProxy,
                        trigger: scrollToSoonestDatestampTrigger,
                        id: topDatestamp
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
            }
        }

        // Build the planner map whenever the calendar store refreshes.
        .externalData(
            key: calendarStore.reloadTrigger,
            ready: true,
            load: buildPlannerMap
        )

        // Schedule a build of the planner map when the search query changes.
        .onChange(of: searchText) { _, _ in schedulePlannerMapBuild() }

        // Schedule a build of the planner map when the filtered calendars change.
        .onChange(of: filteredCalendarIds) { _, _ in
            schedulePlannerMapBuild()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var calendarFilterToolbarMenu: some ToolbarContent {
        if calendarStore.calendarAccessDenied == false {
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Text("Filter Calendars")
                        .font(.footnote)
                    Divider()
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
                                    systemName: calendar.iconName(
                                        settings: settings
                                    )
                                )
                                .tint(calendar.color)

                                Text(calendar.title)
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
            EmptyLabel(
                searchText.isEmpty
                    ? "No Upcoming Events"
                    : "No Matching Events"
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

    private func upcomingYearHeader(_ year: String) -> some View {
        Text(year)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundColor(.secondary)
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
    }

    // MARK: - Datestamp Builders

    private func buildPlannerMap() {
        // TODO: implement complex calculation
    }

    private func schedulePlannerMapBuild() {
        plannerMapTask?.cancel()

        plannerMapTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                buildPlannerMap()

            } catch {}
        }
    }

}
