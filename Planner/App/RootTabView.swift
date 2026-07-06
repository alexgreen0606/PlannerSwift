//
//  RootTabView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Contacts
import ContactsUI
import EventKit
import Fuse
import SwiftData
import SwiftDate
import SwiftUI

struct RootTabView: View {
    private let settings: Settings

    init(
        modelContext: ModelContext,
        plannerCoverStore: PlannerCoverStore,
        ekEventStore: EKEventStore,
        settings: Settings
    ) {
        self.settings = settings

        // Date picker -> 5 minute intervals.
        UIDatePicker.appearance().minuteInterval = 5

        // Navigation titles -> rounded fonts.
        if var descriptor =
            UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded)
        {
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            UINavigationBar.appearance().largeTitleTextAttributes = [
                .font: UIFont(
                    descriptor: descriptor,
                    size: descriptor.pointSize
                )
            ]
        }

        // Navigation subtitles -> rounded fonts.
        if var descriptor =
            UIFontDescriptor
            .preferredFontDescriptor(withTextStyle: .headline)
            .withDesign(.rounded)
        {
            descriptor = descriptor.addingAttributes([
                .traits: [
                    UIFontDescriptor.TraitKey.weight: UIFont.Weight.heavy
                ]
            ])

            UINavigationBar.appearance().titleTextAttributes = [
                .font: UIFont(
                    descriptor: descriptor,
                    size: descriptor.pointSize
                )
            ]
        }
        
        let todayService = TodayService(
            modelContext: modelContext
        )

        self._plannerService = StateObject(
            wrappedValue: PlannerService(
                modelContext: modelContext,
                ekEventStore: ekEventStore,
                todayService: todayService,
                plannerCoverStore: plannerCoverStore,
                settings: settings
            )
        )
        self._todayService = StateObject(
            wrappedValue: todayService
        )
    }

    private let contactsStore = CNContactStore()

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @AppStorage("lastCleansedMonthstamp") var lastCleansedMonthstamp: String =
        ""

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            .oneMonth

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @Query private var routines: [Routine]

    @StateObject private var todayService: TodayService
    @StateObject private var plannerService: PlannerService

    @State private var selectedTab: TabId = .dashboard

    @Namespace private var namespace

    private var searchRefreshTrigger: String {
        "\(scenePhase)_\(selectedTab)"
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if routines.count == 7 {
                // MARK: Standard App Navigation

                TabView(selection: $selectedTab) {
                    Tab(
                        "",
                        systemImage: todayService.todaystamp
                            .calendarSymbolName,
                        value: .dashboard
                    ) {
                        DashboardRootView(
                            settings: settings,
                            namespace: namespace
                        )
                    }

                    Tab("", systemImage: "list.bullet", value: .checklists) {
                        ChecklistNavigationView()
                    }

                    Tab("", systemImage: "gear", value: .settings) {
                        SettingsRootView(settings: settings)
                    }

                    Tab(value: .search, role: .search) {
                        PlannerLoaderView(datestamp: todayService.todaystamp) {
                            planner in
                            SearchRootView(
                                todayPlanner: planner,
                                settings: settings,
                                namespace: namespace
                            )
                        }
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .accentColor(accentColor.swiftUiColor)
                .opacity(plannerCoverStore.showTodayDefault ? 0 : 1)

                // MARK: Default App Landing. Today Planner.

                PlannerContextLoaderView(
                    datestamp: plannerCoverStore.todaystampAtInit,
                    settings: settings
                ) { context in
                    PlannerRootView(
                        planner: context.planner,
                        sortedPlannerEvents: context.eventContext
                            .sortedPlannerEvents,
                        sortedEventChips: context.eventContext.sortedEventChips,
                        sortedBirthdayChips: context.eventContext
                            .sortedBirthdayChips,
                        settings: settings
                    )
                }
                .opacity(plannerCoverStore.showTodayDefault ? 1 : 0)
            }
        }

        // MARK: Initialize results on the search page.
        .task {
            plannerService.search()
        }

        // MARK: Refresh planners at midnight.
        .task(id: todayService.todaystamp) {
            plannerService.refresh()
        }

        // MARK: Search each time the search tab is active.
        .onChange(of: searchRefreshTrigger) { _, searchRefreshTrigger in
            if scenePhase == .active && selectedTab == .search {
                plannerService.search()
            }
        }

        // MARK: Sync calendar data when the app focuses.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                calendarStore.refreshCalendarsAndAccess()
                syncAppIconWithSettings(
                    accentColor: accentColor,
                    systemColorScheme: systemColorScheme
                )
                plannerService.syncVisiblePlannersCalendar()
            }
        }

        // MARK: Sync weather data when the device's location changes.
        .onChange(
            of: locationService.deviceClLocation?.coordinate.id
        ) {
            _,
            _ in
            weatherCacheService.beginReload()
        }

        // MARK: Planner Cover
        .fullScreenCover(item: $plannerCoverStore.context) { context in
            PlannerContextLoaderView(
                datestamp: context.datestamp,
                settings: settings
            ) { plannerContext in
                PlannerRootView(
                    planner: plannerContext.planner,
                    sortedPlannerEvents: plannerContext.eventContext
                        .sortedPlannerEvents,
                    sortedEventChips: plannerContext.eventContext
                        .sortedEventChips,
                    sortedBirthdayChips: plannerContext.eventContext
                        .sortedBirthdayChips,
                    settings: settings
                )
                .id(context.datestamp)
            }
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: namespace
                )
            )
            .interactiveDismissDisabled(true)
        }

        // MARK: Pass the services up the tree.
        .environmentObject(plannerService)
        .environmentObject(todayService)

        // TODO: move this to RootLoaderView
        .task {
            initializeAppData()
        }
    }

    // MARK: - Functions

    /// Runs each time the app opens.
    private func initializeAppData() {
        // Update the app icon to match the theme settings.
        syncAppIconWithSettings(
            accentColor: accentColor,
            systemColorScheme: systemColorScheme
        )

        // Ensure needed data exists in storage.
        modelContext.ensureRootFolder()
        modelContext.ensureRoutines()

        // Request access for external data.
        calendarStore.refreshCalendarsAndAccess()
        Task {
            try? await contactsStore.requestAccess(for: .contacts)
        }

        // Clean stale storage data.
        cleanseStorage()
    }

    /// Runs once a day (if app is opened).
    private func cleanseStorage() {
        guard lastCleansedMonthstamp != todayService.todaystamp.monthstamp
        else {
            return
        }

        lastCleansedMonthstamp = todayService.todaystamp.monthstamp

        if keepPastEventsDuration != .forever {
            modelContext.deleteStaleData(
                cutoffDate: keepPastEventsDuration.cutoffDate
            )
        }

        modelContext.safeSave("RootTabView cleanseStorage")
    }
}
