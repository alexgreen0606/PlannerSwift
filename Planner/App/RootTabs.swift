//
//  RootTabs.swift
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
    init() {
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
    }

    private let contactsStore = CNContactStore()

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @AppStorage("lastCleansedDatestamp") var lastCleansedDatestamp: String = ""

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            .oneMonth

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var weatherCacheService: WeatherCacheService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @Query private var plannerSettingsList: [PlannerSettings]

    @StateObject private var plannerSearchStore = PlannerSearchStore()

    @Namespace private var namespace

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            if let settings {
                // MARK: Standard App Navigation

                TabView {
                    Tab(
                        "",
                        systemImage: todayService.todaystamp
                            .calendarSymbolName
                    ) {
                        DashboardRootView(
                            settings: settings,
                            namespace: namespace
                        )
                    }

                    Tab("", systemImage: "list.bullet") {
                        ChecklistsRootView()
                    }

                    Tab("", systemImage: "gear") {
                        SettingsRootView(settings: settings)
                    }

                    Tab(role: .search) {
                        PlannerLoaderView(datestamp: todayService.todaystamp) { planner in
                            SearchRootView(
                                todayPlanner: planner,
                                settings: settings,
                                namespace: namespace
                            )
                            .environmentObject(plannerSearchStore)
                        }
                    }
                }
                .tabBarMinimizeBehavior(.onScrollDown)
                .accentColor(accentColor.color)
                .opacity(plannerCoverStore.showTodayDefault ? 0 : 1)

                // MARK: Default App Landing. Today Planner.

                PlannerContextLoaderView(
                    datestamp: plannerCoverStore.todaystampAtInit,
                    settings: settings
                ) { context in
                    PlannerRootView(
                        planner: context.planner,
                        sortedPlannerEvents: context.eventContext.sortedPlannerEvents,
                        calendarDayData: context.eventContext.calendarDayData,
                        settings: settings
                    )
                }
                .opacity(plannerCoverStore.showTodayDefault ? 1 : 0)
            }
        }
        .task {
            initializeAppData()
            initializeSearchResults()
        }

        // MARK: Planner Cover

        .fullScreenCover(item: $plannerCoverStore.context) { context in
            if let settings {
                PlannerContextLoaderView(
                    datestamp: context.datestamp,
                    settings: settings
                ) { plannerContext in
                    PlannerRootView(
                        planner: plannerContext.planner,
                        sortedPlannerEvents: plannerContext.eventContext.sortedPlannerEvents,
                        calendarDayData: plannerContext.eventContext.calendarDayData,
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
        }

        // MARK: Refresh external data when the app focuses.

        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                calendarStore.refreshCalendarsAndAccess()
                syncAppIconWithSettings(
                    accentColor: accentColor,
                    systemColorScheme: systemColorScheme
                )
                plannerSyncService.syncCalendar()
            }
        }

        // MARK: Refresh weather data when the device's location changes.

        .onChange(
            of: locationService.deviceClLocation?.coordinate.key
        ) {
            _,
            _ in
            weatherCacheService.beginReload()
        }
    }

    // MARK: - Functions

    // TODO: find a way to initialize the search query in init.
    private func initializeSearchResults() {
        guard let settings else { return }

        let todayPlanner = modelContext.getPlanner(
            for: todayService.todaystamp
        )

        let todayStartOfDay = todayPlanner.datestamp.startOfDay(
            in: todayPlanner.region(settings: settings)
        )

        plannerSearchStore.search(
            with: PlannerSearchQuery(
                text: "",
                calendarIds: [],
                past: false,
                todayStartOfDay: todayStartOfDay,
                fuse: Fuse()
            ),
            modelContainer: modelContext.container,
            modelContext: modelContext,
            plannerSyncService: plannerSyncService,
            todaystamp: todayService.todaystamp,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore
        )
    }

    /// Runs each time the app opens.
    private func initializeAppData() {
        // Update the app icon to match the theme settings.
        syncAppIconWithSettings(
            accentColor: accentColor,
            systemColorScheme: systemColorScheme
        )

        // Ensure needed data exists in storage.
        modelContext.ensurePlannerSettings(
            settings: plannerSettingsList
        )
        modelContext.ensureRootFolder()

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
        guard lastCleansedDatestamp != todayService.todaystamp else {
            return
        }

        lastCleansedDatestamp = todayService.todaystamp

        if keepPastEventsDuration != .forever {
            modelContext.deleteStaleData(
                cutoffDate: keepPastEventsDuration.cutoffDate
            )
        }

        modelContext.safeSave("RootTabs.cleanseStorage")
    }
}
