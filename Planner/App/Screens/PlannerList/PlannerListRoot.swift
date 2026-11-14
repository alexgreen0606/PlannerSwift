//
//  PlannerListRoot.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import SwiftData
import SwiftUI

struct PlannerListRootView: View {
    private let settings: Settings
    private let namespace: Namespace.ID

    init(
        todayService: TodayService,
        settings: Settings,
        namespace: Namespace.ID
    ) {
        self.settings = settings
        self.namespace = namespace

        _draftSearchQuery = State(
            initialValue: todayService.defaultSearchQuery
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerService: PlannerService

    @State private var navigationPath = NavigationPath()

    @State private var draftSearchQuery: PlannerSearchQuery
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool

    private var plannerListContext: PlannerListContext {
        plannerService.plannerListContext
    }

    private var activeQuery: PlannerSearchQuery? {
        plannerService.activeQuery
    }

    private var structuredDatestamps: StructuredDatestampsContext {
        plannerListContext.structuredDatestamps
    }

    private var isSearchingText: Bool {
        return activeQuery?.text.trimmed.isEmpty == false
    }

    private var filterCount: Int? {
        guard let activeQuery else {
            return nil
        }

        var count = 0

        if activeQuery.past {
            count += 1
        }

        count += activeQuery.calendarIds.count

        if count > 0 {
            return count
        }

        return nil
    }

    private var noResultsLabel: LocalizedStringKey {
        guard let activeQuery else {
            return "No upcoming plans"
        }

        return
            "No matching events, trips, or locations in the \(activeQuery.timeFrameLabel)"

    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                                PlannerContextLoaderView(
                                    datestamp: datestamp,
                                    settings: settings
                                ) {
                                    plannerContext in
                                    PlannerListPreviewView(
                                        planner: plannerContext.planner,
                                        sortedPlannerEvents: plannerContext
                                            .eventContext
                                            .sortedPlannerEvents,
                                        sortedEventChips: plannerContext
                                            .eventContext.sortedEventChips,
                                        sortedBirthdayChips: plannerContext
                                            .eventContext
                                            .sortedBirthdayChips,
                                        settings: settings,
                                        namespace: namespace
                                    )
                                }
                                .listRowBackground(Color.clear)
                            }
                        } header: {
                            if year != todayService.todaystamp.year {
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
                    plannerService.reloadPlannerList()
                }
                .background(Color.appBackground.ignoresSafeArea())
                .safeAreaBar(edge: .bottom) {
                    searchBar
                }
                .overlay {
                    noResultsLabelView
                }
                .toolbar {
                    PlannerFilterToolbarView(
                        draftQuery: $draftSearchQuery,
                        filterCount: filterCount,
                        settings: settings
                    )

                    ToolbarItem(placement: .topBarLeading) {
                        Button("", systemImage: "magnifyingglass") {
                            isSearchFocused = true
                        }
                        .badge(
                            isSearchingText ? "1" : nil
                        )
                    }

                    ToolbarSpacer(.fixed, placement: .topBarLeading)

                    if filterCount != nil || isSearchingText {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Reset") {
                                draftSearchQuery =
                                    todayService.defaultSearchQuery

                                withAnimation {
                                    search()
                                }
                            }
                        }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("", systemImage: "gear") {
                            isSearchFocused = false
                            navigationPath.append(
                                PlannerListPageId.settings
                            )
                        }
                    }
                }

                // MARK: Scroll to top whenever the search results change.

                .withScrollTrigger(
                    scrollProxy: scrollProxy,
                    trigger: structuredDatestamps.datestamps,
                    id: structuredDatestamps.topDatestamp,
                    disabled: structuredDatestamps.topDatestamp == nil
                )
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

        // MARK: Schedule a search each time the draft query changes.

        .onChange(of: draftSearchQuery) { _, _ in
            scheduleSearch()
        }
    }

    // MARK: - View Helpers

    @ViewBuilder
    private var searchBar: some View {
        HStack {
            SearchBarView(
                text: $draftSearchQuery.text,
                isFocused: $isSearchFocused,
                placeholder: "Search planner..."
            )

            GlassIconButtonView(
                systemImageName: "xmark",
                onTap: {
                    draftSearchQuery.text = ""
                    isSearchFocused = false
                }
            )
        }
        .opacity(isSearchFocused ? 1 : 0)
        .padding(
            EdgeInsets(
                top: 16,
                leading: 16,
                bottom: 8,
                trailing: 16
            )
        )
    }

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

    // MARK: - Functions

    private func search() {
        plannerService.loadPlannerList(matching: draftSearchQuery)
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
