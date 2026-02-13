//
//  PlannerSearch.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerSearchTabView: View {
    @Binding var searchText: String

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @Environment(\.isSearching) private var isSearching
    @Environment(\.modelContext) private var modelContext
    @Query private var calendarSettingsList: [CalendarSettings]

    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todaystampWatcher: TodaystampWatcher

    @State private var plannerCoverContext: PlannerCoverContext?
    @Namespace private var sheetAnimation

    @State private var filterDebounce: Task<Void, Never>?
    @State private var filterCalendarIds: Set<String> = []
    @State private var refreshKey: UUID = UUID()

    // Holds all calendar data displayed in the UI.
    @State private var eventMap: [String: [String]] = [:]
    
    @State private var toolbarHeight: CGFloat = 0
    @State private var topInsetHeight: CGFloat = 49

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var sortedUpcomingYears: [String] {
        Array(eventMap.keys).sorted()
    }

    private var sortedCalendars: [EKCalendar] {
        calendarStore.sortedCalendars.filter {
            calendarSettings != nil
                && !calendarSettings!.hiddenCalendarIds.contains(
                    $0.calendarIdentifier
                )
        }
    }

    private var topDatestamp: String? {
        guard let firstYear = sortedUpcomingYears.first else {
            return nil
        }

        return eventMap[firstYear]?.first
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    List {
                        ForEach(sortedUpcomingYears, id: \.self) { year in
                            Section {
                                ForEach(eventMap[year] ?? [], id: \.self) {
                                    datestamp in
                                    PlannerCardView(
                                        datestamp: datestamp,
                                        iconMap: calendarSettings?.iconMap
                                            ?? [:],
                                        isEventChecked: isCalendarEventChecked,
                                    ) {
                                        plannerCoverContext =
                                            PlannerCoverContext(
                                                datestamp: datestamp
                                            )
                                    }
                                    .matchedTransitionSource(
                                        id: datestamp,
                                        in: sheetAnimation
                                    )
                                    .id(datestamp)
                                }
                            } header: {
                                upcomingYearHeader(year)
                            }
                            .listSectionMargins(.top, 0)
                        }
                    }
                    .listStyle(.plain)
                    .overlay {
                        if sortedUpcomingYears.isEmpty {
                            EmptyLabel(
                                searchText.isEmpty
                                    ? "No Upcoming Events"
                                    : "No Matching Events"
                            )
                        }
                    }
                    .safeAreaInset(edge: .top) {
                        Color.clear
                            .frame(
                                height: topInsetHeight
                            )
                    }
                    .ignoresSafeArea(edges: .top)
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: isSearching ? toolbarHeight : 0)
                    }
                    .background(Color.appBackground)
                    .toolbar {
                        topLeftToolbar
                    }

                    // Open a planner.
                    .fullScreenCover(item: $plannerCoverContext) { context in
                        PlannerView(datestamp: context.datestamp) {
                            plannerCoverContext = nil
                        }
                        .navigationTransition(
                            .zoom(
                                sourceID: context.datestamp,
                                in: sheetAnimation
                            )
                        )
                    }

                    // Debounce the filtering of calendar events when needed.
                    .onChange(of: searchText) { _, _ in scheduleFilterDebounce()
                    }
                    .onChange(of: filterCalendarIds) { _, _ in
                        scheduleFilterDebounce()
                    }
                    .onChange(of: calendarSettings?.checkedCalendarEventIds) {
                        _,
                        _ in
                        scheduleFilterDebounce()
                    }

                    // Reload the data from the page.
                    .refreshable {
                        calendarStore.refresh(
                            hiddenCalendarIds: calendarSettings?
                                .hiddenCalendarIds
                                ?? []
                        )
                    }

                    // Calendar Data
                    .externalData(
                        key: calendarStore.refreshKey,
                        ready: calendarSettings != nil,
                        load: computeFilteredEventMap
                    )

                    // Keep the list scrolled to the top whenever the results change.
                    .withScrollTrigger(
                        proxy: proxy,
                        trigger: refreshKey,
                        id: topDatestamp
                    )
                    
                    // Calculate the layout values once the UI settles.
                    .onAppear {
                        DispatchQueue.main.async {
                            toolbarHeight = geo.safeAreaInsets.bottom
                            topInsetHeight = geo.safeAreaInsets.top - toolbarHeight + 16
                        }
                    }
                }
            }
        }
    }

    private var calendarFilter: some View {
        Group {
            if !calendarStore.accessDenied {
                Menu {
                    Text("Filter Calendars")
                        .font(.footnote)
                    Divider()
                    ForEach(sortedCalendars, id: \.calendarIdentifier) {
                        calendar in
                        Toggle(
                            isOn: Binding(
                                get: {
                                    filterCalendarIds.contains(
                                        calendar.calendarIdentifier
                                    )
                                },
                                set: { isOn in
                                    if isOn {
                                        filterCalendarIds.insert(
                                            calendar.calendarIdentifier
                                        )
                                    } else {
                                        filterCalendarIds.remove(
                                            calendar.calendarIdentifier
                                        )
                                    }
                                }
                            )
                        ) {
                            HStack(spacing: 8) {
                                Image(
                                    systemName:
                                        calendarSettings?.iconMap[
                                            calendar.calendarIdentifier
                                        ] ?? calendar.iconName
                                )
                                .tint(Color(cgColor: calendar.cgColor))

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

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        if !calendarStore.accessDenied {
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
                                    filterCalendarIds.contains(
                                        calendar.calendarIdentifier
                                    )
                                },
                                set: { isOn in
                                    if isOn {
                                        filterCalendarIds.insert(
                                            calendar.calendarIdentifier
                                        )
                                    } else {
                                        filterCalendarIds.remove(
                                            calendar.calendarIdentifier
                                        )
                                    }
                                }
                            )
                        ) {
                            HStack(spacing: 8) {
                                Image(
                                    systemName:
                                        calendarSettings?.iconMap[
                                            calendar.calendarIdentifier
                                        ] ?? calendar.iconName
                                )
                                .tint(Color(cgColor: calendar.cgColor))

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

    private func isCalendarEventChecked(event: EKEvent?) -> Bool {
        guard let calendarSettings, let event else {
            return false
        }

        return calendarSettings.checkedCalendarEventIds.contains(
            event.calendarItemExternalIdentifier
        )
    }

    private func upcomingYearHeader(_ year: String) -> some View {
        Text(year)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundColor(.secondary).frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
    }

    private func computeFilteredEventMap() {
        let today = todaystampWatcher.todaystamp
        let todayDate = today.toDate("yyyy-MM-dd", region: .local)?.date
        let maxDate = todaystampWatcher.maxCalendarDate

        // ------------------------------------------------------------------
        // 1. Collect all datestamps that have events (all-day + single-day)
        // ------------------------------------------------------------------
        let eventDatestamps = Set(
            calendarStore.allDayEventsByDatestamp.keys
        ).union(
            calendarStore.singleDayEventsByDatestamp.keys
        )

        // ------------------------------------------------------------------
        // 2. Trim datestamps to the desired date range
        // ------------------------------------------------------------------
        let dateRangeFiltered: [(year: String, datestamp: String)] =
            eventDatestamps.compactMap { datestamp in
                guard
                    let date = datestamp.toDate("yyyy-MM-dd", region: .local)?
                        .date,
                    let todayDate,
                    date > todayDate,
                    date < maxDate
                else { return nil }

                return (String(date.year), datestamp)
            }

        // ------------------------------------------------------------------
        // 3. Filter events by:
        //    a) calendar IDs (if provided)
        //    b) checked status
        //    c) search text in title (if provided)
        //    Remove datestamps with zero remaining events
        // ------------------------------------------------------------------
        let filteredDatestamps = dateRangeFiltered.compactMap {
            entry -> (year: String, datestamp: String)? in
            let datestamp = entry.datestamp

            // Combine all events for this datestamp
            let events =
                (calendarStore.allDayEventsByDatestamp[datestamp] ?? [])
                + (calendarStore.singleDayEventsByDatestamp[datestamp] ?? [])

            // Filter by calendar identifiers (skip if none selected)
            let calendarFiltered =
                filterCalendarIds.isEmpty
                ? events
                : events.filter {
                    filterCalendarIds.contains($0.calendar.calendarIdentifier)
                }

            // Filter out checked events
            let checkedFiltered =
                calendarSettings == nil
                ? calendarFiltered
                : calendarFiltered.filter {
                    !calendarSettings!.checkedCalendarEventIds.contains(
                        $0.calendarItemExternalIdentifier
                    )
                }

            let trimmedSearchText = searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            // Filter by search text in title (skip if empty)
            let searchFiltered =
                trimmedSearchText.isEmpty
                ? checkedFiltered
                : checkedFiltered.filter {
                    $0.title.localizedCaseInsensitiveContains(
                        trimmedSearchText
                    )
                }

            // Remove this datestamp entirely if no events remain
            guard !searchFiltered.isEmpty else { return nil }

            return entry
        }

        // ------------------------------------------------------------------
        // 4. Group remaining datestamps by year
        // ------------------------------------------------------------------
        let grouped = Dictionary(grouping: filteredDatestamps, by: { $0.year })

        // ------------------------------------------------------------------
        // 5. Sort datestamps within each year
        // ------------------------------------------------------------------
        eventMap = grouped.mapValues { values in
            values
                .map { $0.datestamp }
                .sorted()
        }

        refreshKey = UUID()
    }

    private func scheduleFilterDebounce() {
        filterDebounce?.cancel()

        filterDebounce = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                // Recompute filtered event map.
                computeFilteredEventMap()
            } catch {
            }
        }
    }

}
