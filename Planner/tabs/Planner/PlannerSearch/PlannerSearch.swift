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

struct PlannerCoverContext: Identifiable {
    var datestamp: String
    var namespace: Namespace.ID

    var id: String {
        "\(datestamp)-\(namespace)"
    }
}

enum PlannerRoute: Hashable {
    case settings
}

struct PlannerSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var calendarSettingsList: [CalendarSettings]

    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todaystampWatcher: TodaystampWatcher
    @ObservedObject var weatherStore = WeatherStore.shared

    @StateObject private var plannerManager = ListManager()

    @State private var plannerCoverContext: PlannerCoverContext?
    @Namespace private var toolbarAnimation
    @Namespace private var thisWeekAnimation
    @Namespace private var upcomingAnimation

    @State private var searchText: String = ""
    @State private var filterDebounce: Task<Void, Never>?
    @State private var isCalendarPickerOpen = false
    @State private var selectedCalendarDate: Date = Date()
    @State private var filterCalendarIds: Set<String> = []
    @State private var isNewEventSheetOpen = false

    // Holds all calendar data displayed in the UI.
    @State private var eventMap: [String: [String]] = [:]
    
    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var thisWeekDatestamps: [String] {
        let region = Region.local
        let today = DateInRegion(Date(), region: region)

        return (0..<7).map {
            today
                .dateByAdding($0, .day)
                .toFormat("yyyy-MM-dd")
        }.sorted()
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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("This week")
                        .padding(.leading, 16)
                        .font(.headline)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                        .listRowInsets(.bottom, 0)
                        .discreetListItem()

                    ScrollView(.horizontal) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(thisWeekDatestamps, id: \.self) {
                                datestamp in
                                PlannerCardVerticalView(
                                    datestamp: datestamp,
                                    iconMap: calendarSettings?.iconMap ?? [:]
                                ) {
                                    plannerCoverContext = PlannerCoverContext(
                                        datestamp: datestamp,
                                        namespace: thisWeekAnimation
                                    )
                                }
                                .matchedTransitionSource(
                                    id: datestamp,
                                    in: thisWeekAnimation
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .scrollIndicators(.hidden)
                    .background(Color.clear)
                }
                .listRowInsets(.horizontal, 0)
                .discreetListItem()

                if sortedUpcomingYears.isEmpty {
                    EmptyLabel("No upcoming events")
                        .frame(maxWidth: .infinity)
                        .discreetListItem()
                }

                ForEach(sortedUpcomingYears, id: \.self) { year in
                    Section {
                        ForEach(eventMap[year] ?? [], id: \.self) {
                            datestamp in
                            PlannerCardView(
                                datestamp: datestamp,
                                iconMap: calendarSettings?.iconMap ?? [:]
                            ) {
                                plannerCoverContext = PlannerCoverContext(
                                    datestamp: datestamp,
                                    namespace: upcomingAnimation
                                )
                            }
                            .matchedTransitionSource(
                                id: datestamp,
                                in: upcomingAnimation
                            )
                            .overlay {
                                if year == sortedUpcomingYears.first!
                                    && datestamp == eventMap[year]!
                                        .first!
                                {
                                    HStack(alignment: .top) {
                                        Text("Coming up")
                                            .font(.headline)
                                            .foregroundStyle(
                                                Color(uiColor: .secondaryLabel)
                                            )
                                            .offset(y: -48)
                                    }
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .frame(
                                        maxHeight: .infinity,
                                        alignment: .top
                                    )
                                }
                            }
                        }
                    } header: {
                        upcomingYearHeader(year)
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.appBackground)
            .navigationTitle("Planner")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Calendar", systemImage: "calendar") {
                        isCalendarPickerOpen = true
                    }
                    .popover(isPresented: $isCalendarPickerOpen) {
                        VStack {
                            DatePicker(
                                "Open a planner",
                                selection: $selectedCalendarDate,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .onChange(of: selectedCalendarDate) {
                                _,
                                targetPlannerDate in
                                isCalendarPickerOpen = false

                                DispatchQueue.main.async {
                                    plannerCoverContext = PlannerCoverContext(
                                        datestamp: targetPlannerDate.datestamp,
                                        namespace: toolbarAnimation
                                    )
                                }
                            }
                        }
                        .frame(width: 340, height: 320)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                    }
                    .matchedTransitionSource(
                        id: "CALENDAR",
                        in: toolbarAnimation
                    )
                }

                ToolbarItem(placement: .topBarTrailing) {
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button("New Event", systemImage: "plus") {
                        isNewEventSheetOpen = true
                    }
                    .matchedTransitionSource(
                        id: "NEW_EVENT",
                        in: toolbarAnimation
                    )
                }
            }
            .fullScreenCover(item: $plannerCoverContext) { context in
                NavigationStack {
                    PlannerView(datestamp: context.datestamp) {
                        plannerCoverContext = nil
                    }
                }
                .environmentObject(plannerManager)
                .navigationTransition(
                    .zoom(
                        sourceID: context.namespace == toolbarAnimation
                            ? "CALENDAR" : context.datestamp,
                        in: context.namespace
                    )
                )
            }
            .sheet(isPresented: $isNewEventSheetOpen) {
                EditCalendarEventView(
                    event: EKEvent(eventStore: calendarStore.ekEventStore),
                    eventStore: calendarStore.ekEventStore
                ) { action, event in
                    calendarStore.refresh(
                        hiddenCalendarIds: calendarSettings?.hiddenCalendarIds
                            ?? []
                    )
                    isNewEventSheetOpen = false
                }
                .navigationTransition(
                    .zoom(
                        sourceID: "NEW_EVENT",
                        in: toolbarAnimation
                    )
                )
            }
            // Debounce the filtering of calendar events when needed.
            .onChange(of: searchText) { _, _ in scheduleFilterDebounce() }
            .onChange(of: filterCalendarIds) { _, _ in scheduleFilterDebounce()
            }
            .onChange(of: calendarStore.refreshKey) { _, newKey in
                computeFilteredEventMap()
            }
            // Load in the calendar data and settings.
            .task {
                modelContext.ensureCalendarSettings(
                    settings: calendarSettingsList
                )

                calendarStore.requestAccessAndLoadIfNeeded(
                    hiddenCalendarIds: calendarSettings?.hiddenCalendarIds ?? []
                )
            }
            // Reload the data from the page.
            .refreshable {
                calendarStore.refresh(
                    hiddenCalendarIds: calendarSettings?.hiddenCalendarIds ?? []
                )
                Task {
                    await weatherStore.loadWeather()
                }
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search calendar events..."
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
        let todayDate = today.toDate("yyyy-MM-dd", region: .local)
        let oneYearOut = todayDate?.dateByAdding(3, .year)

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
                    let date = datestamp.toDate("yyyy-MM-dd", region: .local),
                    let todayDate,
                    let oneYearOut,
                    date > todayDate,
                    date < oneYearOut
                else { return nil }

                return (String(date.year), datestamp)
            }

        // ------------------------------------------------------------------
        // 3. Filter events by:
        //    a) calendar IDs (if provided)
        //    b) search text in title (if provided)
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

            let trimmedSearchText = searchText.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            // Filter by search text in title (skip if empty)
            let searchFiltered =
                trimmedSearchText.isEmpty
                ? calendarFiltered
                : calendarFiltered.filter {
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
                // Task cancelled — do nothing.
            }
        }
    }

}
